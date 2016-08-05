module LocalServicesHelper
  def make_authority(tier, options)
    authority = FactoryGirl.create(:local_authority,
                                   snac: options[:snac], tier: tier)
    authority
  end

  def make_service(lgsl_code, providing_tier)
    LocalService.create!(lgsl_code: lgsl_code, providing_tier: providing_tier)
  end

  def make_authority_providing(_lgsl_code, tier = 'county')
    council = FactoryGirl.create(:local_authority, snac: "00AA", tier: tier)
    council
  end
end
