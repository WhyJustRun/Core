module Tools
  # Merges a duplicate (source) user account into a primary (target) account,
  # porting the legacy CakePHP Merge behavior as configured on the User model:
  # associated rows are re-pointed to the target, and a fixed set of profile
  # fields is kept from the target but filled from the source when the
  # target's value is NULL ('target_source' strategy). The source account is
  # destroyed afterwards. The target keeps its own password.
  class UserMerge
    # Fields merged with the 'target_source' strategy
    FILLABLE_FIELDS = %w[year_of_birth club_id si_number email referred_from].freeze

    def self.merge(target, source)
      User.transaction do
        Membership.where(user_id: source.id).update_all(user_id: target.id)
        Organizer.where(user_id: source.id).update_all(user_id: target.id)
        Result.where(user_id: source.id).update_all(user_id: target.id)
        Privilege.where(user_id: source.id).update_all(user_id: target.id)
        Result.where(registrant_id: source.id).update_all(registrant_id: target.id)

        FILLABLE_FIELDS.each do |field|
          target[field] = source[field] if target[field].nil?
        end
        # Saved without validations like the legacy behavior did; the source
        # row still holds the same email at this point, which would trip the
        # uniqueness validation.
        target.save!(validate: false)
        source.destroy!
      end
    end
  end
end
