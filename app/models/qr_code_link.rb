class QrCodeLink
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def signed
    self.class.verifier.generate(@url, purpose: :qr_code)
  end

  def self.from_signed(signed)
    new verifier.verify(signed, purpose: :qr_code)
  end

  private
    class << self
      def verifier
        ActiveSupport::MessageVerifier.new(secret, url_safe: true)
      end

      def secret
        Rails.application.key_generator.generate_key("qr_codes")
      end
    end
end
