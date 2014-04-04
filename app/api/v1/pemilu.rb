# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Pemilu
    class APIv1 < Grape::API
        version 'v1', using: :accept_version_header
        prefix 'api'
        format :json
        resource :caleg do
            desc "Return all Polygon of Dapils"
            get do              
            polygons = MapitGeometry.find_all_data(params)
              {
                results: polygons
              }
            end
        end
        resource :point do
          desc "Return all Dapil/Provinsi based on point"
          get do
            areas = MapitGeometry.find_all_data_by_point(params)
            {
              results: {
                count: areas.count,
                total: areas.count,
                areas: areas
              }
            }
          end
        end
        resource :area do
          desc "Return details of Area by Area Id"
          params do
            requires :id, type: String, desc: "Area Id."
          end
          route_param :id do
            get do
              details_area = MapitGeometry.find_details_area(params)
              {
                results: details_area
              }
            end
          end
        end
        resource :getmap do
        desc "Return data from file"         
          get do
            MapitGeometry.get_file_data(params)
          end
        end
    end
    
end
