module Presentation
  class ChapelService < Base

    before_save :update_description

    def preacher
      return outside_speaker unless outside_speaker.blank?

      presenter&.name || "Sign up to Lead!"
    end

    def hymn
      metadata["hymn"]
    end

    def hymn=(value)
      metadata["hymn"] = value
    end

    def readings
      metadata["readings"] || []
    end

    def readings=(value)
      metadata["readings"] = Array.wrap(value)
    end

    def joined_readings
      readings.join("\n")
    end

    def liturgy
      metadata["liturgy"]
    end

    def liturgy=(value)
      metadata["liturgy"] = value
    end

    def outside_speaker
      metadata["outside_speaker"]
    end

    def outside_speaker=(value)
      metadata["outside_speaker"] = value
    end

    def send_summary!
      ChapelMailer.summary(self).deliver_later!
      self.summary_sent = true
      save
    end

    def summary_complete?
      !liturgy.blank? && !hymn.blank?
    end

    def summary_sent?
      !!metadata["summary_sent"]
    end

    def summary_sent=(value)
      metadata["summary_sent"] = !!value
    end

  private

    def update_description
      self.description = <<~MD
        **Preacher:** #{preacher}

        **Liturgist:** #{presenter&.name || "None"}

        **Liturgy:** #{liturgy}

        **Hymn:** #{hymn}

        **Reading(s):** #{readings.join("; ")}
      MD
    end

  end
end
