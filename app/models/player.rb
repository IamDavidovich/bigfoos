class Player < ActiveRecord::Base
  belongs_to :team
  belongs_to :user
  has_many :score, :dependent => :destroy

  class << self
    def for_user(game,user)
      team_ids = game.teams.pluck(:id)
      Player.where(team_id: team_ids, user_id: user.id).first
    end
  end

  ##
  # Gives a point to the player
  #
  def score
    s = Score.new
    s.game = self.team.game
    s.player = self
    s.save
  end

  ##
  # Takes away a point from the player
  #
  def unscore
    s = Score.where(:player_id => self.id, :game_id => self.team.game.id).first
    if s
      s.destroy
    else
      false
    end
  end

  ##
  # Sets the player to win the game
  #
  def win
    self.user.inc_stat(:wins)
    self.won = true
    self.finish
  end

  ##
  # Sets the player lose the game
  #
  def lose
    self.user.inc_stat(:losses)
    self.won = false
    self.finish
  end

  ##
  # finishes the game and stores a stat on position playing
  #
  def finish
    self.user.inc_stat(('played_'+self.position).to_sym)
    self.user.inc_stat(:games)
    self.user.recalculate_win_loss_ratio
    self.user.do_score
    self.save
  end

  ##
  # Tells if this player is the top scorer for the game
  #
  def top_scorer?
    team_ids = self.team.game.teams.pluck(:id)
    Player.where(:team_id => team_ids).maximum(:points) == self.points
  end

  ##
  # Get the players team color
  #
  def team_color
    self.team.color.downcase
  end

  ##
  # Get the other team's color
  #
  def other_teams_color
    self.team_color == 'yellow' ? 'black' : 'yellow'
  end

  ##
  # Get the opposing team of the player
  #
  def other_team
    self.team.other_team
  end

  def inc_score_stats
    self.user.inc_stat(:scores)
    self.user.inc_stat(:score_as_front) if self.position == 'front'
    self.user.inc_stat(:score_as_back) if self.position == 'back'
    self.other_team.players.each do |p|
      p.user.inc_stat(:scored_against)
      p.user.inc_stat(:scored_against_as_front) if p.position == 'front'
      p.user.inc_stat(:scored_against_as_back) if p.position == 'back'
    end if self.other_team
  end

  def dec_score_stats
    self.user.dec_stat(:scores)
    self.other_team.players.each do |p|
      p.user.dec_stat(:scored_against)
      p.user.dec_stat(:scored_against_as_front) if p.position == 'front'
      p.user.dec_stat(:scored_against_as_back) if p.position == 'back'
    end if self.other_team
  end
end
