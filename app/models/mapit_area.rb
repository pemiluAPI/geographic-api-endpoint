class MapitArea < ActiveRecord::Base
    self.table_name = :mapit_area
    has_many :mapit_geometry, foreign_key: "area_id"
end