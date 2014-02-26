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
    end
    
end
