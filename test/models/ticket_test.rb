require 'test_helper'
require 'mail' unless Object.const_defined? :Mail

class TicketTest < ActiveSupport::TestCase
  def setup
    @ticket = tickets(:enhancement)
  end
    
  test 'validates blank attributes' do
    @ticket.from_addresses = ''
    @ticket.subject = ''
    
    assert @ticket.invalid?
    assert_error @ticket, :from_addresses, :blank
    assert_error @ticket, :subject, :blank
  end
    
  test 'validates attribute length' do
    @ticket.subject = 'abcde' * 52
    
    assert @ticket.invalid?
    assert_error @ticket, :subject, :too_long, count: 255
  end

  test 'from addresses' do
    @ticket.from_addresses = 'one@one.net, two@two.net, three@three.net'

    assert_equal %w(one@one.net two@two.net three@three.net), @ticket.from
    assert_equal 'one@one.net, two@two.net, three@three.net', @ticket.from_addresses
  end

  test 'receive new message' do
    assert_difference 'Ticket.count' do
      Ticket.receive_mail mail
    end
  end

  test 'receive new multipart message' do
    assert_difference 'Ticket.count' do
      Ticket.receive_mail multipart_mail
    end
  end

  test 'receive message update' do
    mail = mail(with_id: true)

    assert_no_difference 'Ticket.count' do
      Ticket.receive_mail mail
    end

    assert_equal mail.body.decoded, @ticket.reload.body
  end

  private

  def mail with_id: false
    mail = create_mail with_id: with_id
    mail.body = "Some\nbody =)"

    mail
  end

  def multipart_mail with_id: false
    mail = create_mail with_id: with_id

    mail.text_part = Mail::Part.new do
      body 'Text body'
    end

    mail.html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body '<h1>HTML body</h1>'
    end

    mail
  end

  def create_mail with_id: false
    _headers = { 'X-Ticket-ID' => @ticket.id.to_s }

    Mail.new do
      headers _headers if with_id
      from    'nobody@test.net'
      to      'support@postman.com'
      subject 'Test email'
    end
  end
end
