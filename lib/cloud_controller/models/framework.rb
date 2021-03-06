# Copyright (c) 2009-2012 VMware, Inc.

module VCAP::CloudController::Models
  class Framework < Sequel::Model
    plugin :serialization

    one_to_many :apps

    default_order_by  :name
    export_attributes :name, :description, :internal_info
    import_attributes :name, :description, :internal_info

    strip_attributes  :name

    serialize_attributes :json, :internal_info

    def validate
      validates_presence :name
      validates_presence :description
      validates_presence :internal_info
      validates_unique   :name
    end

    def self.populate_from_directory(dir_name)
      Dir[File.join(dir_name, "*.yml")].each do |file_name|
        populate_from_file file_name
      end
    end

    def self.populate_from_file(file_name)
      populate_from_hash YAML.load_file(file_name)
    end

    def self.populate_from_hash(config)
      Framework.update_or_create(:name => config["name"]) do |r|
        r.update(
          :description => config["name"],
          :internal_info => config
        )
      end
    end
  end
end
