RSpec.describe RelatonIev do
  it "has a version number" do
    expect(RelatonIev::VERSION).not_to be nil
  end

  it "manipulates a document" do
    bibdb = Relaton::Db.new nil, nil
    xmldoc = Nokogiri::XML <<~XML_DOC
      <standard-document>
        <bibitem type="inline" bibitemid="a" docidentifier="IEC 60050:2011">
          <eref citeas="IEC 60050:2011">
            <locality type="clause">
            <referenceFrom>102-01-01</referenceFrom>
            </locality>
          </eref>
        </bibitem>
        <sections/>
      </standard-document>
    XML_DOC
    VCR.use_cassette "iec" do
      expect(RelatonIev.iev_cleanup(xmldoc, bibdb).first).to be_instance_of Nokogiri::XML::Element
    end
  end
end
