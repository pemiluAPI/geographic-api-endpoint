require 'spec_helper'

describe Pemilu::API do
  before (:each) do
    @dprd1 = create(:dprd1)
    @dprd1geometry = create(:dprd1geometry)    
  end

  describe "GET /api/caleg?&long=123.02454625900009&lat=0.558759166000186" do
    it "Return all areas and related caleg by coordinates" do
      get "/api/caleg?&long=123.02454625900009&lat=0.558759166000186"
      response.status.should == 200
      response.body.should == {
        results: [{
          kind: "Dapil",
          lembaga: "DPRDI",
          id: "7500-01-0000",
          nama: @dprd1.name,
          count: 0,
          total: 0,
          caleg: []
        }]
      }.to_json
    end
  end
  
  describe "GET /api/area/7500-01-0000" do
    it "Return coordinates of an area" do
      get "/api/area/7500-01-0000"
      response.status.should == 200
      response.body.should == {
        results: [{
          kind: "Dapil",
          id: "7500-01-0000",
          nama: @dprd1.name,
          lembaga: "DPRDI",
          type: "Polygon",
          coordinates: [
              JSON.parse("[[123.01776674400003,0.529525092000029],[123.02454625900009,0.558759166000186],
[123.06453336600008,0.588360870000031],[123.0909527750001,0.58031690200005],[123.08383556600006,0.542209945000025],
[123.07923794800013,0.523047215000076],[123.0989892560001,0.50446046400009],[123.09167767300004,0.482618448000096],
[123.06269816200029,0.505789362000087],[123.04271131800022,0.496308738999971],[123.03892947000007,0.513316184000075],
[123.01776674400003,0.529525092000029]]")
          ]
        }]
      }.to_json
    end
  end
  
  describe "GET /api/point?&long=123.02454625900009&lat=0.558759166000186" do
    it "Return all areas by coordinates" do
      get "/api/point?&long=123.02454625900009&lat=0.558759166000186"
      response.status.should == 200
      response.body.should == {
        results: {
          count: 1,
          total: 1,
          areas: [{
            kind: "Dapil",
            id: "7500-01-0000",
            nama: @dprd1.name,
            lembaga: "DPRDI"
          }]
        }
      }.to_json
    end
  end
end