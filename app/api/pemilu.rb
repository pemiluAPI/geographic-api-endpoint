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
            polygons = MapitGeometry.find_all_data(params)
              {
                results: {
                  count: polygons.count,
                  polygons: polygons
                }
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
    end
    
end
