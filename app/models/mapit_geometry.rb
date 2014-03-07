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
      areas = Array.new
      unless params[:lat].nil?
        all_polygon = MapitGeometry.joins(:mapit_area).references(:mapit_area)              
        .select("mapit_geometry.id, mapit_geometry.area_id, mapit_area.name,mapit_area.type_id").order("mapit_geometry.id")
        all_polygon = all_polygon.where("ST_Intersects(polygon,ST_GeometryFromText('POINT(? ?)',?))",
            params[:long].to_f, params[:lat].to_f, 4326) unless params[:lat].nil?
        if params[:lembaga] == "DPR"
          all_polygon = all_polygon.where("mapit_area.type_id = ? or type_id = ?",4, 5)
          all_polygon.each do |polygon|
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            dapil_prov = get_provinsi_and_dapil(polygon, polygon.type_id)
            kind = polygon.type_id == 5 ? "Provinsi" : "Dapil"
            lembaga = polygon.type_id == 5 ? "DPD" : dapil_prov["nama_lembaga"]

              areas << {
                kind: kind,
                lembaga: lembaga,
                id: dapil_prov["id"],
                nama: polygon.name,
                count: caleg.count,
                total: caleg.count,
                caleg: caleg              
              }          
          end
        elsif params[:lembaga] == "DPD"
          all_polygon = all_polygon.where("mapit_area.type_id = ?",5)
          all_polygon.each do |polygon|
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            dapil_prov = get_provinsi_and_dapil(polygon, polygon.type_id)
            kind = polygon.type_id == 5 ? "Provinsi" : "Dapil"
            lembaga = polygon.type_id == 5 ? "DPD" : dapil_prov["nama_lembaga"]         
              areas << {
                kind: kind,
                lembaga: lembaga,
                id: dapil_prov["id"],
                nama: polygon.name,
                count: caleg.count,
                total: caleg.count,
                caleg: caleg
              }          
          end
        elsif params[:lembaga] == "DPRDI"
          all_polygon = all_polygon.where("mapit_area.type_id = ?",6)
          all_polygon.each do |polygon|
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            dapil_prov = get_provinsi_and_dapil(polygon, polygon.type_id)
            kind = polygon.type_id == 5 ? "Provinsi" : "Dapil"
            lembaga = polygon.type_id == 5 ? "DPD" : dapil_prov["nama_lembaga"]          
            areas << {
                kind: kind,
                lembaga: lembaga,
                id: dapil_prov["id"],
                nama: polygon.name,
                count: caleg.count,
                total: caleg.count,
                caleg: caleg
            }          
          end      
        else        
          all_polygon.each do |polygon|
            caleg = get_caleg(polygon, params[:lembaga], polygon.type_id)
            dapil_prov = get_provinsi_and_dapil(polygon, polygon.type_id)
            if polygon.type_id == 4 || polygon.type_id == 6            
              areas << {
                kind: "Dapil",
                lembaga: dapil_prov["nama_lembaga"],
                id: dapil_prov["id"],
                nama: polygon.name,
                count: caleg.count,
                total: caleg.count,
                caleg: caleg
              }
            elsif polygon.type_id == 5
              areas << {
                kind: "Provinsi",
                lembaga: "DPD",
                id: dapil_prov["id"],
                nama: polygon.name,
                count: caleg.count,
                total: caleg.count,
                caleg: caleg
              }
            end
          end
        end
      end
      areas
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
      first_area = Array.new
      features = Array.new
      arr_coord = Array.new
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
            @type = JSON.parse(polygon.st_asgeojson)['type']
            @coord = JSON.parse(polygon.st_asgeojson)['coordinates']
          end
          kind = area.type_id == 5 ? "Provinsi" : "Dapil"
          lembaga = area.type_id == 5 ? "DPD" : first_area["nama_lembaga"]          
          if params[:type] == "geojson"
            features << {
              type: "Feature",
              properties: {
                kind: kind,
                id: first_area["id"],
                nama: first_area["nama_lengkap"],
                lembaga: lembaga,
              },
              geometry: {
                type: @type,
                coordinates: @coord
              }
            }
              details_area << {
                type: "FeatureCollection",
                features: features
            }
          elsif params[:type] == "topojson"
            scale = [2,2]
            translate = [1,1]
            arcs = Array.new            
            all_polygon.each do |polygon|
              arr_coord = JSON.parse(polygon.st_asgeojson)['coordinates']              
              arr_coord.each do |coords|
                @coor = coords
              end
              @coor.each_with_index do |coor, index|
                @arc = (coor[0] - translate[0])/scale[0],(coor[1] - translate[1])/scale[1]                
                
                if (index != 0)
                  temp = arcs[index-1]
                  
                  @arc[0] = @arc[0] - temp[0]
                  @arc[1] = @arc[1] - temp[1]
                end
                
                
                arcs << @arc
                #raise arcs.inspect
              end              
            end
            details_area << {
              type: "Topology",
              transform: {
                scale: scale,
                translate: translate,
              },
              object: {
                type: "GeometryCollection",
                geometries:  [{
                  type: @type,
                  arcs: "[[0]]",
                }]
              },
              arcs: arcs
            }
          else
            details_area << {
              kind: kind,
              id: first_area["id"],
              nama: first_area["nama_lengkap"],
              lembaga: lembaga,
              type: @type,
              coordinates: @coord
            }
          end
        end        
      end        
    end
    def self.get_file_data(params=Hash.new())
      unless params[:filename].nil?
        file_url = HTTParty.get("#{Rails.configuration.file_url}/#{params[:filename]}")        
        results = file_url.parsed_response if (file_url.code == 200)
      end
      results.gsub(/[\u0022]/,'')
    end
end