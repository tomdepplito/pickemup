# == Schema Information
#
# Table name: github_accounts
#
#  id                 :uuid             not null, primary key
#  nickname           :string(255)
#  hireable           :boolean
#  bio                :text
#  public_repos_count :integer
#  number_followers   :integer
#  number_following   :integer
#  number_gists       :integer
#  blog               :string(255)
#  token              :string(255)
#  github_account_key :string(255)
#  uid                :string(255)
#  user_id            :uuid
#  created_at         :datetime
#  updated_at         :datetime
#  skills             :string(255)      default([])
#

class GithubAccount < ActiveRecord::Base
  include Extensions

  belongs_to :user
  has_many :repos, class_name: 'Repo', foreign_key: 'github_account_id', dependent: :destroy
  has_many :organizations, dependent: :destroy

  after_create :grab_github_information

  #create a user's github account from their github auth information when they login
  def from_omniauth(auth)
    info                    = auth.info
    extra_info              = auth.extra.raw_info
    self.nickname           = info.nickname
    self.hireable           = extra_info.hireable
    self.bio                = extra_info.bio
    self.public_repos_count = extra_info.public_repos
    self.number_followers   = extra_info.followers
    self.number_following   = extra_info.following
    self.number_gists       = extra_info.public_gists
    self.token              = auth.credentials.token
    self.uid                = auth.uid
    self.github_account_key = extra_info.id
    self.save
  end

  #this method is used to setup the repos and orgs from a user's github oauth token
  def setup_information
    Repo.from_omniauth(get_repos, self.id, self.collected_repo_keys)
    Organization.from_omniauth(get_organizations, self.id, self.collected_org_keys)
    self.set_skills(get_repos)
  end

  def set_skills(repos)
    collected_languages = repos.inject([]) do |languages, repo|
      languages << get_languages(repo)
      languages
    end.flatten.uniq.select { |lang| lang.is_a?(String) }
    self.update(skills: collected_languages)
  end

  #use mode from /concerns/extensions to get most common language
  def most_common_language
    self.repos.collect { |repo| repo.language }.mode
  end

  #get more information regarding a user's organization by the organization name
  def get_org_information(name)
    begin
      github_api_setup.orgs.get(name)
    rescue Exception => e
      logger.error "Github #get_org_information error #{e}"
    end
  end

  #collect the org keys associated with github that we can use to remove any
  #orgs from our system that have been removed on github
  def collected_org_keys
    self.organizations.collect { |org| org.organization_key }
  end

  #collect the repo keys associated with github that we can use to remove any
  #repos from our system that have been removed on github
  def collected_repo_keys
    self.repos.collect { |repo| repo.repo_key }
  end

  #instance method for getting a users's github account url
  def github_url
    "https://github.com/#{self.nickname}"
  end

  private

  def grab_github_information
    GithubWorker.perform_async(self.id)
  end

  #instantiate the github api with user's oauth token
  def github_api_setup
    @github_api ||= Github.new(oauth_token: self.token)
  end

  #get all the public repos from a user's github account
  def get_repos
    begin
      @repos ||= github_api_setup.repos.list
    rescue Exception => e
      logger.error "Github #get_repos error #{e}"
    end
  end

  def get_languages(repo)
    begin
      github_api_setup.repos.languages(self.nickname, repo.name).try(:keys)
    rescue Exception => e
      logger.error "Github #get_languages error #{e}"
    end
  end

  #get all the organizations from a user's github account
  def get_organizations
    begin
      github_api_setup.organizations.list
    rescue Exception => e
      logger.error "Github #get_organizations error #{e}"
    end
  end
end
