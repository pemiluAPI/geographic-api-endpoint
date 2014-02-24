class MapitGeometry < ActiveRecord::Base
    self.primary_key = :id
    self.table_name = :mapit_geometry
     belongs_to :mapit_area, foreign_key: "area_id"
end