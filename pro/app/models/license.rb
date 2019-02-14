class License
  PRO_FEATURES = %i[
    soft_delete
  ]

  class << self
    delegate :expired?, :will_expire?, :expires_at,
             :restrictions, :restricted?, :starts_at, to: :license

    def features
      PRO_FEATURES
    end

    def allow_feature?(name)
      return false if trial? && expired?

      features.include?(name)
    end

    def trial?
      restricted_attr(:trial).present?
    end

    def remaining_days
      return 0 if expired?

      (expires_at - Date.today).to_i
    end

    def license?
      license && license.valid?
    end

    def restricted_attr(attr, default: nil)
      return default unless license? && restricted?(attr)

      restrictions[attr]
    end

    def license
      @license ||=
        begin
          BookLab::License.import(Setting.license)
        rescue BookLab::License::ImportError
          nil
        end
    end
  end
end