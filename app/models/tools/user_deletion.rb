module Tools
  # Deletes a user account to honour a data deletion request. The person's
  # results are kept for the event records but re-pointed at the "(deleted)"
  # placeholder user, and the free-text comment they wrote on their own
  # results is cleared. Everything else tied to the account is removed.
  class UserDeletion
    def self.delete(user)
      raise ArgumentError, 'cannot delete the placeholder user' if user.deleted_placeholder?

      User.transaction do
        placeholder = User.deleted_placeholder
        summary = {
          results: Result.where(user_id: user.id).count,
          memberships: Membership.where(user_id: user.id).count,
          organizers: Organizer.where(user_id: user.id).count,
          officials: Official.where(user_id: user.id).count,
          privileges: Privilege.where(user_id: user.id).count
        }

        Result.where(user_id: user.id).update_all(user_id: placeholder.id, registrant_comment: nil)
        Result.where(registrant_id: user.id).update_all(registrant_id: placeholder.id, registrant_comment: nil)
        ResultList.where(user_id: user.id).update_all(user_id: nil)
        [Membership, Organizer, Official, Privilege].each { |model| model.where(user_id: user.id).delete_all }

        user.destroy!
        summary
      end
    end
  end
end
