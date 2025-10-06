require 'json'
require 'securerandom'
require 'fileutils'

class Persistence
  STORAGE_ROOT = File.expand_path('../../data', __dir__)

  def self.env
    ENV['FORESIGHT_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  def self.storage_dir
    File.join(STORAGE_ROOT, env)
  end

  def self.ensure_dir!
    FileUtils.mkdir_p(storage_dir) unless Dir.exist?(storage_dir)
  end

  def self.generate_key
    SecureRandom.hex(16)
  end

  def self.path_for(key)
    ensure_dir!
    File.join(storage_dir, "#{key}.json")
  end

  # Backward-compat: pre-env file location
  def self.legacy_path_for(key)
    File.join(STORAGE_ROOT, "#{key}.json")
  end

  def self.load(key)
    return nil unless key
    path = path_for(key)
    legacy = legacy_path_for(key)
    real_path = if File.exist?(path)
      path
    elsif File.exist?(legacy)
      legacy
    else
      nil
    end
    return nil unless real_path
    JSON.parse(File.read(real_path), symbolize_names: true)
  rescue StandardError
    nil
  end

  def self.save(key, payload)
    ensure_dir!
    File.write(path_for(key), JSON.pretty_generate(payload))
    true
  rescue StandardError
    false
  end

  def self.save_legacy(key, payload)
    FileUtils.mkdir_p(STORAGE_ROOT) unless Dir.exist?(STORAGE_ROOT)
    File.write(legacy_path_for(key), JSON.pretty_generate(payload))
    true
  rescue StandardError
    false
  end

  def self.delete(key)
    path = path_for(key)
    return true unless File.exist?(path)
    File.delete(path)
    true
  rescue StandardError
    false
  end
end
