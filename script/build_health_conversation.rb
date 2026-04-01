# frozen_string_literal: true

# Dev utility: metrics relaxed for a single runnable script.
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/ParameterLists, Rails/SkipsModelValidations

# Builds a single "health" themed conversation with 300 messages (150 client / 150 agent),
# including every Message content_type and message_type at least once.
#
# Usage:
#   bundle exec rails runner script/build_health_conversation.rb
#
# Optional ENV:
#   ACCOUNT_ID   — defaults to first account
#   INBOX_ID     — defaults to first Channel::WebWidget inbox (or first inbox)
#   ASSIGNEE_ID  — defaults to first user on the account

HEALTH_CLIENT_LINES = [
  'I need to refill my blood pressure medication.',
  'Can you confirm my appointment for next Tuesday?',
  'I have been having headaches in the morning.',
  'Do you take my insurance — policy number is on file?',
  'What are the side effects of the new prescription?',
  'I missed a dose yesterday; what should I do?',
  'Can I get a copy of my lab results?',
  'Is telehealth available for follow-up?',
  'My symptoms got worse over the weekend.',
  'Do I need to fast before the blood draw?',
  'I am traveling — can I get a 90-day supply?',
  'The pharmacy says the prior auth is still pending.',
  'I would like to switch to a different time slot.',
  'Is the flu shot available at your clinic?',
  'I have a question about the discharge instructions.'
].freeze

HEALTH_AGENT_LINES = [
  'I have noted your refill request and will send it to the provider.',
  'Your appointment is confirmed; you will receive a calendar invite.',
  'Let us schedule a brief triage call to review your symptoms.',
  'I can verify insurance — please allow a few minutes while I check.',
  'I will share the patient education sheet on that medication.',
  'For a missed dose, take the next dose at the usual time unless advised otherwise.',
  'I am releasing your lab results to the portal now.',
  'Yes, we offer telehealth for eligible follow-up visits.',
  'I am escalating this to the care team for review today.',
  'Fasting is required for this panel — water is fine.',
  'I will coordinate with the pharmacy for a travel supply.',
  'I will follow up with insurance on the prior authorization.',
  'I have moved your visit to the new slot you requested.',
  'Flu shots are in stock; I can add one to your visit.',
  'I have attached the discharge checklist again for convenience.'
].freeze

def resolve_account
  id = ENV['ACCOUNT_ID'].presence
  id ? Account.find(id) : Account.order(:id).first
end

def resolve_inbox(account)
  if ENV['INBOX_ID'].present?
    account.inboxes.find(ENV['INBOX_ID'])
  else
    account.inboxes.find_by(channel_type: 'Channel::WebWidget') || account.inboxes.order(:id).first
  end
end

def resolve_assignee(account)
  if ENV['ASSIGNEE_ID'].present?
    account.users.find(ENV['ASSIGNEE_ID'])
  else
    account.users.order(:id).first
  end
end

def build_incoming_pool
  pool = Array.new(150) { :text }
  # Spread special incoming types (5) + keep 145 plain text
  { 28 => :sticker, 56 => :incoming_email, 84 => :voice_in, 112 => :location, 140 => :image }.each do |idx, kind|
    pool[idx] = kind
  end
  pool
end

def build_outgoing_pool
  pool = Array.new(150) { :text }
  specials = {
    12 => :template_email,
    24 => :template_csat,
    36 => :template_cards,
    48 => :template_select,
    60 => :template_form,
    72 => :template_article,
    84 => :template_input_text,
    96 => :template_input_textarea,
    108 => :integrations,
    120 => :voice_out,
    132 => :sticker,
    138 => :private_note,
    144 => :activity
  }
  specials.each { |idx, kind| pool[idx] = kind }
  pool
end

def create_incoming!(conversation, contact, account, inbox, base_time, seq, kind, text_idx)
  attrs = {
    account: account,
    inbox: inbox,
    conversation: conversation,
    message_type: :incoming,
    content_type: :text,
    created_at: base_time + seq.seconds,
    updated_at: base_time + seq.seconds,
    processed_message_content: nil
  }

  case kind
  when :text
    attrs[:content] = "#{HEALTH_CLIENT_LINES[text_idx % HEALTH_CLIENT_LINES.length]} (#{text_idx + 1})"
    attrs[:sender] = contact
    attrs[:processed_message_content] = attrs[:content]
  when :sticker
    attrs[:content_type] = :sticker
    attrs[:content] = '🩺'
    attrs[:sender] = contact
    attrs[:processed_message_content] = attrs[:content]
  when :incoming_email
    attrs[:content_type] = :incoming_email
    attrs[:content] = 'Subject: Question about lab results'
    attrs[:content_attributes] = { email: { subject: 'Question about lab results', text_content: { reply: 'See attached.' } } }
    attrs[:sender] = contact
    attrs[:processed_message_content] = attrs[:content]
  when :voice_in
    attrs[:content_type] = :voice_call
    attrs[:content] = 'Voice call'
    attrs[:content_attributes] = { data: { 'call_sid' => "CA_IN_#{seq}", 'status' => 'completed', 'call_direction' => 'inbound' } }
    attrs[:sender] = contact
    attrs[:processed_message_content] = attrs[:content]
  when :location
    attrs[:content] = 'location'
    attrs[:sender] = contact
    m = Message.new(attrs)
    m.attachments.new(
      account_id: account.id,
      file_type: 'location',
      coordinates_lat: 37.7893768,
      coordinates_long: -122.3895553,
      fallback_title: 'Medical center, San Francisco, CA'
    )
    m.save!
    return m
  when :image
    attrs[:content] = 'Photo of insurance card'
    attrs[:sender] = contact
    m = Message.new(attrs)
    m.attachments.new(
      account_id: account.id,
      file_type: :image,
      external_url: 'https://www.chatwoot.com/images/chatwoot-brand.png'
    )
    m.save!
    return m
  end

  Message.create!(attrs)
end

def create_outgoing!(conversation, agent, account, inbox, base_time, seq, kind, text_idx)
  attrs = {
    account: account,
    inbox: inbox,
    conversation: conversation,
    message_type: :outgoing,
    content_type: :text,
    created_at: base_time + seq.seconds,
    updated_at: base_time + seq.seconds,
    sender: agent
  }

  case kind
  when :text
    attrs[:content] = "#{HEALTH_AGENT_LINES[text_idx % HEALTH_AGENT_LINES.length]} (#{text_idx + 1})"
  when :sticker
    attrs[:content_type] = :sticker
    attrs[:content] = '👍'
  when :private_note
    attrs[:content] = 'Internal: verified member ID with payer portal.'
    attrs[:private] = true
  when :activity
    return Message.create!(
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: :activity,
      content_type: :text,
      content: "#{agent.name} updated priority",
      sender: nil,
      created_at: base_time + seq.seconds,
      updated_at: base_time + seq.seconds
    )
  when :voice_out
    attrs[:content_type] = :voice_call
    attrs[:content] = 'Voice call'
    attrs[:content_attributes] = { data: { 'call_sid' => "CA_OUT_#{seq}", 'status' => 'completed', 'call_direction' => 'outbound' } }
  when :integrations
    attrs[:content_type] = :integrations
    attrs[:content] = 'Video visit link (demo integration)'
    attrs[:content_attributes] = { type: 'dyte', data: { meeting_id: "meet-#{seq}" } }
  when :template_email
    attrs[:message_type] = :template
    attrs[:content_type] = :input_email
    attrs[:content] = 'Share your email for appointment reminders'
    attrs[:sender] = nil
  when :template_csat
    attrs[:message_type] = :template
    attrs[:content_type] = :input_csat
    attrs[:content] = 'Please rate your visit'
    attrs[:sender] = nil
  when :template_cards
    attrs[:message_type] = :template
    attrs[:content_type] = :cards
    attrs[:content] = 'cards'
    attrs[:content_attributes] = { items: [Seeders::MessageSeeder.sample_card_item] }
    attrs[:sender] = nil
  when :template_select
    attrs[:message_type] = :template
    attrs[:content_type] = :input_select
    attrs[:content] = 'Reason for visit'
    attrs[:content_attributes] = {
      items: [
        { title: 'Follow-up', value: 'follow_up' },
        { title: 'New issue', value: 'new_issue' }
      ]
    }
    attrs[:sender] = nil
  when :template_form
    attrs[:message_type] = :template
    attrs[:content_type] = :form
    attrs[:content] = 'form'
    attrs[:content_attributes] = Seeders::MessageSeeder.sample_form
    attrs[:sender] = nil
  when :template_article
    attrs[:message_type] = :template
    attrs[:content_type] = :article
    attrs[:content] = 'Help articles'
    attrs[:content_attributes] = {
      items: [
        { title: 'Preparing for labs', description: 'Fasting and hydration tips', link: 'https://example.com/labs' }
      ]
    }
    attrs[:sender] = nil
  when :template_input_text
    attrs[:message_type] = :template
    attrs[:content_type] = :input_text
    attrs[:content] = 'Please type your member ID'
    attrs[:sender] = nil
  when :template_input_textarea
    attrs[:message_type] = :template
    attrs[:content_type] = :input_textarea
    attrs[:content] = 'Describe your symptoms'
    attrs[:sender] = nil
  end

  Message.create!(attrs)
end

account = resolve_account
raise 'No account found. Seed the DB or set ACCOUNT_ID.' if account.blank?

inbox = resolve_inbox(account)
raise 'No inbox found.' if inbox.blank?

assignee = resolve_assignee(account)
raise 'No user found on account to assign. Create a user or set ASSIGNEE_ID.' if assignee.blank?

contact_inbox = ContactInboxWithContactBuilder.new(
  source_id: "health_demo_#{SecureRandom.hex(6)}",
  inbox: inbox,
  contact_attributes: { name: 'Health Demo Patient', email: "health.demo.#{SecureRandom.hex(4)}@example.com" }
).perform

conversation = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact_inbox.contact,
  contact_inbox: contact_inbox,
  status: :open,
  assignee: assignee,
  custom_attributes: { subject: 'Health — demo thread (300 messages)' }
)

incoming_pool = build_incoming_pool
outgoing_pool = build_outgoing_pool
base_time = 48.hours.ago

incoming_text_idx = 0
outgoing_text_idx = 0

Message.skip_callback(:commit, :after, :execute_after_create_commit_callbacks)
begin
  300.times do |seq|
    if seq.even?
      kind = incoming_pool[seq / 2]
      tidx = if kind == :text
               i = incoming_text_idx
               incoming_text_idx += 1
               i
             else
               0
             end
      create_incoming!(
        conversation, contact_inbox.contact, account, inbox, base_time, seq, kind, tidx
      )
    else
      kind = outgoing_pool[seq / 2]
      tidx = if kind == :text
               i = outgoing_text_idx
               outgoing_text_idx += 1
               i
             else
               0
             end
      create_outgoing!(
        conversation, assignee, account, inbox, base_time, seq, kind, tidx
      )
    end
  end
ensure
  Message.set_callback(:commit, :after, :execute_after_create_commit_callbacks)
end

conversation.update_columns(
  last_activity_at: base_time + 400.seconds,
  updated_at: Time.current
)

msgs = conversation.reload.messages
puts <<~SUMMARY
  Health conversation created.
  Account ID:    #{account.id}
  Inbox ID:      #{inbox.id}
  Conversation:  #{conversation.display_id} (id=#{conversation.id})
  Messages:      #{msgs.count} (expected 300)
  Client (incoming): #{msgs.incoming.count}
  Agent (outgoing):  #{msgs.outgoing.count}
  Templates:         #{msgs.template.count}
  Activity:          #{msgs.where(message_type: :activity).count}
SUMMARY

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/ParameterLists, Rails/SkipsModelValidations
