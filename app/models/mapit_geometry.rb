class MapitGeometry < ActiveRecord::Base
    self.table_name = :mapit_geometry
     belongs_to :mapit_area, foreign_key: "area_id"
end