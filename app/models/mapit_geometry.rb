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
    
    def self.get_provinsi_and_dapil(polygon, type)      
      if (type == 4 || type == 6)        
        encode_dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
        dapil_end = HTTParty.get(encode_dapil_url, timeout: 500)        
        result = dapil_end.parsed_response['data']['results']['dapil'].first
      elsif (type == 5)
        encode_provinsi_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/provinsi?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
        provinsi_end = HTTParty.get(encode_provinsi_url, timeout: 500)
        result = provinsi_end.parsed_response['data']['results']['provinsi'].first        
      end
      result
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
    
    def self.find_all_data_by_point(params = Hash.new())
      areas = Array.new
      all_polygon = MapitGeometry.joins(:mapit_area).references(:mapit_area)              
      .select("mapit_geometry.id, mapit_geometry.area_id, mapit_area.name,mapit_area.type_id").order("mapit_geometry.id")
      .where("ST_Intersects(polygon,ST_GeometryFromText('POINT(? ?)',?))",
      params[:long].to_f, params[:lat].to_f, 4326) unless params[:lat].nil?
      all_polygon.each do |polygon|
        result = get_provinsi_and_dapil(polygon, polygon.type_id) 
        kind = polygon.type_id == 5 ? "Provinsi" : "Dapil"
        lembaga = polygon.type_id == 5 ? "DPD" : result["nama_lembaga"]
        areas << {
          kind: kind,
          id: result["id"],
          nama: result["nama_lengkap"],
          lembaga: lembaga
        }
      end
      areas
    end
    
    def self.find_details_area(params=Hash.new())
      details_area = Array.new
      coord = Array.new
      first_area = Array.new
      dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil/#{params[:id]}?apiKey=#{Rails.configuration.pemilu_api_key}")
      dapil_end = HTTParty.get(dapil_url, timeout: 500)      
      first_area = dapil_end.parsed_response['data']['results']['dapil'].first unless dapil_end.parsed_response['data'].nil?      
      if first_area.empty?
        provinsi_url = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/provinsi/#{params[:id].to_i}?apiKey=#{Rails.configuration.pemilu_api_key}")
        provinsi_end = HTTParty.get(provinsi_url, timeout: 500)
        first_area = provinsi_end.parsed_response['data']['results']['provinsi'].first unless provinsi_end.parsed_response['data'].nil?
      end
      unless first_area.empty?
        area = MapitArea.where("lower(name) = ?", first_area["nama_lengkap"].downcase).first
        unless area.nil?
          all_polygon = MapitGeometry.select("ST_AsGeoJson(ST_Union(polygon))").where("area_id = ?", area.id)        
          all_polygon.each do |polygon|
            coord << polygon.st_asgeojson.gsub(/[\u0022]/,'')
          end
          kind = area.type_id == 5 ? "Provinsi" : "Dapil"
          lembaga = area.type_id == 5 ? "DPD" : first_area["nama_lembaga"]
          details_area << {
            kind: kind,
            id: first_area["id"],
            nama: first_area["nama_lengkap"],
            lembaga: lembaga,
            coordinates: coord
          }
        end        
      end        
    end
end