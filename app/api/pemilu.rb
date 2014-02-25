# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Pemilu
    class API < Grape::API
        prefix 'api'
        format :json
        resource :polygon do
            desc "Return all Polygon of Dapils"
            get do              
              polygons = Array.new
              @all_polygon = MapitGeometry.joins(:mapit_area).references(:mapit_area)              
              .select("mapit_geometry.id, mapit_geometry.area_id, mapit_area.name").order("mapit_geometry.id")
              @all_polygon = @all_polygon.where("ST_Intersects(polygon,ST_GeometryFromText('POINT(? ?)',?))",
                  params[:long].to_f, params[:lat].to_f, 4326) unless params[:lat].nil?
              @all_polygon.each do |polygon|
                unless params[:lat].nil?
                  @encode_dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{polygon.name}")
                  @dapil_end = HTTParty.get(@encode_dapil_url, timeout: 500)
                  @dapil = @dapil_end.parsed_response['data']['results']['dapil'].first
                  @caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&dapil=#{@dapil["id"]}&lembaga=#{params[:lembaga]}", timeout: 500)
                  @caleg = @caleg_end.parsed_response['data']['results']['caleg']
                  polygons << {
                    id_polygon: polygon.id,
                    dapil: polygon.name,
                    caleg: @caleg
                  }
                else
                  polygons << {
                    id_polygon: polygon.id,
                    dapil: polygon.name,
                  }
                end
              end
              {
                results: {
                    count: polygons.count,
                    polygons: polygons
                }
              }
            end
        end
    end
    
end
