class MapitGeometry < ActiveRecord::Base
    self.primary_key = :id
    self.table_name = :mapit_geometry
    belongs_to :mapit_area, foreign_key: "area_id"
    
    def self.get_caleg(polygon, lembaga, type)      
      if (type == 4 || type == 6)        
        encode_dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
        dapil_end = HTTParty.get(encode_dapil_url, timeout: 500)        
        dapil = dapil_end.parsed_response['data']['results']['dapil'].first        
        caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&dapil=#{dapil["id"]}&lembaga=#{lembaga}", timeout: 500)        
      elsif (type == 5)
        encode_provinsi_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/provinsi?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
        provinsi_end = HTTParty.get(encode_provinsi_url, timeout: 500)
        provinsi = provinsi_end.parsed_response['data']['results']['provinsi'].first
        caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&provinsi=#{provinsi["id"]}&lembaga=#{lembaga}", timeout: 500)
      end
      caleg_end.parsed_response['data']['results']['caleg']
    end
  
    def self.find_all_data(params = Hash.new())
      polygons = Array.new
      all_polygon = MapitGeometry.joins(:mapit_area).references(:mapit_area)              
      .select("mapit_geometry.id, mapit_geometry.area_id, mapit_area.name,mapit_area.type_id").order("mapit_geometry.id")
      all_polygon = all_polygon.where("ST_Intersects(polygon,ST_GeometryFromText('POINT(? ?)',?))",
          params[:long].to_f, params[:lat].to_f, 4326) unless params[:lat].nil?
      if params[:lembaga] == "DPR"
        all_polygon = all_polygon.where("mapit_area.type_id = ?",4)
        all_polygon.each do |polygon|
          field = "dapil DPR"
          unless params[:lat].nil?            
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name,
              caleg_results: {
                count: caleg.count,
                caleg: caleg
              }
            }
          else
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name
            }
          end
        end
      elsif params[:lembaga] == "DPD"
        all_polygon = all_polygon.where("mapit_area.type_id = ?",5)
        all_polygon.each do |polygon|
          field = "provinsi DPD"
          unless params[:lat].nil? 
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name,
              caleg_results: {
                count: caleg.count,
                caleg: caleg
              }
            }
          else                  
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name
            }
          end
        end
      elsif params[:lembaga] == "DPRDI"
        all_polygon = all_polygon.where("mapit_area.type_id = ?",6)
        all_polygon.each do |polygon|
          field = "dapil DPRDI"
          unless params[:lat].nil?                  
          caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)          
          polygons << {
            id_polygon: polygon.id,
            "#{field}" => polygon.name,
            caleg_results: {
              count: caleg.count,
              caleg: caleg
            }
          }
          else
            polygons << {
              id_polygon: polygon.id,
              "#{field}" => polygon.name
            }
          end
        end
      else
        all_polygon.each do |polygon|
          if polygon.type_id == 4
            field = "dapil DPR"
            unless params[:lat].nil?                  
              caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name,
                caleg_results: {
                  count: caleg.count,
                  caleg: caleg
                }
              }
            else
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name
              }
            end
          elsif polygon.type_id == 5
            field = "provinsi DPD"
            unless params[:lat].nil? 
              caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name,
                caleg_results: {
                  count: caleg.count,
                  caleg: caleg
                }
              }
            else                  
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name
              }
            end
            elsif polygon.type_id == 6
            field = "Dapil DPRDI"
            unless params[:lat].nil? 
              caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name,
                caleg_results: {
                  count: caleg.count,
                  caleg: caleg
                }
              }
            else                  
              polygons << {
                id_polygon: polygon.id,
                "#{field}" => polygon.name
              }
            end
          end
        end
      end
      polygons
    end
end