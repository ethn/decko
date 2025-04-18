# -*- encoding : utf-8 -*-

class MoveRoles < Cardio::Migration::Transform
  def up
    remove_member_structure_rule
    change_existing_member_cards_to_lists
    populate_member_lists_and_delete_role_lists
  end

  def remove_member_structure_rule
    %i[members right structure].card&.delete!
  end

  def change_existing_member_cards_to_lists
    Card.search(left: { type_id: Card::RoleID },
                right_id: Card::MembersID) do |role_members|
      role_members.update! type_id: Card::ListID
    end
  end

  def populate_member_lists_and_delete_role_lists
    Card.search(left: { type_id: Card::UserID },
                right_id: Card::RolesID) do |user_roles|
      role_names = role_names_from_user_roles_card user_roles.id
      move_role_names user_roles.left.name, role_names if role_names.present?
      user_roles.delete
    end
  end

  def move_role_names user, role_names
    role_names.each do |role_name|
      next unless role_name.card&.type_code == :role

      puts "Move #{user} to role #{role_name}"
      Card.fetch(role_name, :members, new: {}).add_item! user
    end
  end

  def role_names_from_user_roles_card id
    query = "SELECT db_content FROM cards WHERE cards.id = #{id}"
    content = ActiveRecord::Base.connection
                                .exec_query(query)
                                .rows&.first&.first
    return unless content.present?

    content.split "\n"
  end
end
