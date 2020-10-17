class AddClubDomainProtocol < ActiveRecord::Migration[6.0]
  def change
    add_column :clubs, :domain_protocol, :string, default: 'https', null: false, after: :domain
  end
end
