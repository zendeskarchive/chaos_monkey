require "chaos_monkey/version"
require 'rubygems'
require "bundler/setup"
require 'hashie'
require 'fog'
require 'yaml'

module ChaosMonkey
  
  autoload :Config,         'chaos_monkey/config'
  autoload :VERSION,        'chaos_monkey/version'
  
  class << self
    attr_accessor :configuration
    attr_accessor :connection
  end

  config_file = File.open(File.expand_path(File.dirname(File.dirname(__FILE__)))+"/config/cloud.yml")
  config_yml = YAML::load(config_file)

  self.configuration = ChaosMonkey::Config.new
  self.configuration.aws.aws_secret_access_key = config_yml["aws"]["aws_secret_access_key"]
  self.configuration.aws.aws_access_key_id = config_yml["aws"]["aws_access_key_id"]

  self.connection = Fog::Compute.new({
    :provider                 => 'AWS',
    :aws_secret_access_key    => self.configuration.aws.aws_secret_access_key,
    :aws_access_key_id        => self.configuration.aws.aws_access_key_id
  })
  
  
  def self.collect_instance_ids(response)
    response.body["tagSet"].collect{|x| x["resourceId"]}
  end
  
  def self.find_by_tag(tag)
    ChaosMonkey.connection.describe_tags('key' => tag)
  end
  
  def self.find_victims
    response = find_by_tag("chaos")
    instance_ids = collect_instance_ids(response)
  end
  
  def self.choos_victim(ary)
    size = ary.size
    ary[rand(size)]
  end
  
  def self.kill(victim)
    ChaosMonkey.connection.terminate_instances(victim)
    puts "BOOM! #{victim} is dommed!"
  end
  
  def self.unchain
    victims = self.find_victims
    victim = choos_victim(victims)
    kill(victim)
    true
  end
  
end
