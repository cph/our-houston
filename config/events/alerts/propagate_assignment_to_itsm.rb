Houston.config do
  # Notify ITSM of change of assignment
  on "alert:itsm:assign" => "alert:propagate-assignment-to-itsm" do
    itsm = ITSM::Issue.find alert.number
    itsm.assign_to! alert.checked_out_by || "Emerging Products" if itsm
  end
end
