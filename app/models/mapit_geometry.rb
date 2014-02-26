class MapitGeometry < ActiveRecord::Base
    self.primary_key = :id
    self.table_name = :mapit_geometry
    belongs_to :mapit_area, foreign_key: "area_id"
    
    def self.find_all_data(params = Hash.new())
      polygons = Array.new
      all_polygon = MapitGeometry.joins(:mapit_area).references(:mapit_area)              
      .select("mapit_geometry.id, mapit_geometry.area_id, mapit_area.name,mapit_area.type_id").order("mapit_geometry.id")
      all_polygon = all_polygon.where("ST_Intersects(polygon,ST_GeometryFromText('POINT(? ?)',?))",
          params[:long].to_f, params[:lat].to_f, 4326) unless params[:lat].nil?
      all_polygon.each do |polygon|
        if polygon.type_id == 4
          field = "dapil"
          unless params[:lat].nil?                  
            encode_dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
            dapil_end = HTTParty.get(encode_dapil_url, timeout: 500)
            dapil = dapil_end.parsed_response['data']['results']['dapil'].first
            caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&dapil=#{dapil["id"]}&lembaga=#{params[:lembaga]}", timeout: 500)
            caleg = caleg_end.parsed_response['data']['results']['caleg'] 
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name,
              caleg: caleg
            }
          else
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name
            }
          end
        elsif polygon.type_id == 5
          field = "provinsi"
          unless params[:lat].nil? 
            encode_provinsi_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/provinsi?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
            provinsi_end = HTTParty.get(encode_provinsi_url, timeout: 500)
            provinsi = provinsi_end.parsed_response['data']['results']['provinsi'].first
            caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&provinsi=#{provinsi["id"]}&lembaga=#{params[:lembaga]}", timeout: 500)
            caleg = caleg_end.parsed_response['data']['results']['caleg']                    
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name,
              caleg: caleg
            }
          else                  
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name
            }
          end
        end
      end
      polygons
    end
end