Houston.config do
  on "testing_note:create" => "testing:email-ticket-participants-of-note" do
    ticket, verdict = note.ticket, note.verdict
    Houston::TestingReport::Mailer.testing_note(note, ticket.participants).deliver! if verdict == "none"
    Houston::TestingReport::Mailer.testing_note(note, ticket.participants.reject(&:tester?)).deliver! if verdict == "fails"
  end
end
