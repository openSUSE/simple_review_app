class PullRequestCollection
  include ActiveModel::Model
  attr_accessor :username, :password, :repository, :labels

  def all
    authenticate
    pull_requests
  end
  
  def reload
    @pull_request_numbers = @pull_requests = nil
    all
  end
  
  private
  
  def pull_requests
    return @pull_requests if @pull_requests.present?
    @pull_requests = []
    # We have to do roundtrips here as the GitHup API does not support 
    # fetching pull requests by their label
    pull_request_numbers.each do |pull_request_number|
      @pull_requests << Octokit.pull_request(repository, pull_request_number.number)
    end
    @pull_requests
  end
  
  def pull_request_numbers
    return @pull_request_numbers if @pull_request_numbers.present?
    issues = Octokit.list_issues(repository, labels: labels)
    @pull_request_numbers = issues.find_all { |i| i.pull_request }
  end
  
  def authenticate
    return unless credentials?
    Octokit.configure do |c|
      c.login = username
      c.password = password
    end
  end
  
  def credentials?
    username.present? && password.present?
  end
end
