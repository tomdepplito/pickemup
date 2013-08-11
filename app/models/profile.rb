# == Schema Information
#
# Table name: profiles
#
#  id                  :integer          not null, primary key
#  number_connections  :integer
#  number_recommenders :integer
#  summary             :text
#  skills              :string(255)      default([])
#  linkedin_id         :integer
#  created_at          :datetime
#  updated_at          :datetime
#

class Profile < ActiveRecord::Base
  attr_accessible :number_connections, :number_recommenders, :summary,
    :skills

  has_many :positions, dependent: :destroy
  has_many :educations, dependent: :destroy
  belongs_to :linkedin

  #set information from omniauth from a user's linkedin api profile and also
  #setup a user's positions and educations
  def from_omniauth(profile=nil)
    profile = self.linkedin.get_profile unless profile.present?
    self.update(
      summary: profile.summary,
      number_connections: profile.num_connections,
      number_recommenders: profile.num_recommenders,
      skills: self.class.get_skills(profile.skills))
    Position.from_omniauth(profile, self.id, self.collected_position_keys)
    Education.from_omniauth(profile, self.id, self.collected_education_keys)
  end

  #get a collection of all the position keys from linkedin so that we can
  #determine which positions that are in our system have been removed from
  #linkedin's system
  def collected_position_keys
    self.positions.collect { |pos| pos.position_key }
  end

  #get a collection of all the education keys from linkedin so that we can
  #determine which educations that are in our system have been removed from
  #linkedin's system
  def collected_education_keys
    self.educations.collect { |edu| edu.education_key }
  end

  #get all the skills from the linkedin api for a user
  def self.get_skills(skills)
    skills.all.collect { |s| s.skill.name } if skills.total > 0
  end
end
