require 'spec_helper'

describe Pemilu::API do
  before (:each) do
    @dprd1 = create(:dprd1)
    @dprd1geometry1 = create(:dprd1geometry1)
    @dprd1geometry2 = create(:dprd1geometry2)
  end
  
  describe "GET /api/caleg?&long=106.77845&lat=-6.224841085" do
    it "Return all areas and related caleg by coordinates" do
      get "/api/caleg?&long=106.77845&lat=-6.224841085"      
      encode_dapil_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/dapil?apiKey=#{Rails.configuration.pemilu_api_key}&nama=#{@dprd1.name}&lembaga=DPRDI")
      dapil_end = HTTParty.get(encode_dapil_url, timeout: 500)
      dapil = dapil_end.parsed_response['data']['results']['dapil'].first
      caleg_end = HTTParty.get("#{Rails.configuration.pemilu_api_endpoint}/api/caleg?apiKey=#{Rails.configuration.pemilu_api_key}&dapil=#{dapil["id"]}&lembaga=DPRDI", timeout: 500)
      caleg = caleg_end.parsed_response['data']['results']['caleg']
      response.status.should == 200
      response.body.should == {
        results: [{
          kind: "Dapil",
          lembaga: dapil["nama_lembaga"],
          id: dapil["id"],
          nama: @dprd1.name,
          count: caleg.count,
          total: caleg.count,
          caleg: caleg
        }]
      }.to_json
    end
  end
  
  describe "GET /api/area/3100-10-0000" do
    it "Return coordinates of an area" do
      get "/api/area/3100-10-0000"
      response.status.should == 200
      response.body.should == {
        results: [{
          kind: "Dapil",
          id: "3100-10-0000",
          nama: @dprd1.name,
          lembaga: "DPRDI",
          type: "MultiPolygon",
          coordinates: 
              JSON.parse("[[[[106.79815131799998,-6.161383763999878],[106.81065388000013,-6.188723125999957],
[106.79238910799998,-6.207788022999977],[106.77845,-6.22484108499998],[106.73731552299999,-6.22362314399993],
[106.72008534700007,-6.210185076999892],[106.7201692750001,-6.209604280999883],[106.72417187400008,-6.19204953499991],
[106.7240509070001,-6.191571879999913],[106.71648374600004,-6.189828875999979],[106.74773,-6.15804],[106.76662,-6.16049],
[106.77508781800009,-6.145231557999978],[106.78917032200013,-6.142500509999877],[106.79815131799998,-6.161383763999878]]],
[[[106.82127399500013,-6.136870899999849],[106.81070016400002,-6.160828396999932],[106.81044025300012,-6.130844175999924],
[106.82127399500013,-6.136870899999849]]]]")
        }]
      }.to_json
    end
  end
  
  describe "GET /api/point?&long=106.77845&lat=-6.224841085" do
    it "Return all areas by coordinates" do
      get "/api/point?&long=106.77845&lat=-6.224841085"
      response.status.should == 200
      response.body.should == {
        results: {
          count: 1,
          total: 1,
          areas: [{
            kind: "Dapil",
            id: "3100-10-0000",
            nama: @dprd1.name,
            lembaga: "DPRDI"
          }]
        }
      }.to_json
    end
  end
end