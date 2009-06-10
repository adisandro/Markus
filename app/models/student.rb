class Student < User
  SESSION_TIMEOUT = USER_STUDENT_SESSION_TIMEOUT
  # CSV_UPLOAD_ORDER is what we expect the uploaded CSV file to be ordered with
  CSV_UPLOAD_ORDER = USER_STUDENT_CSV_UPLOAD_ORDER
 
  has_many :accepted_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}, :source => :grouping
  
  has_many :pending_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:pending]}, :source => :grouping
  
  has_many :rejected_groupings, :class_name => 'Grouping', :through => :memberships, :conditions => {'memberships.membership_status' => StudentMembership::STATUSES[:rejected]}, :source => :grouping

  has_many :student_memberships

  
  # Returns true if this student has a Membership in a Grouping for an
  # Assignment with id 'aid', where that Membership.membership_status is either
  # 'accepted' or 'inviter'
  def has_accepted_grouping_for?(aid)
    return !accepted_grouping_for(aid).nil?
  end
  
  # Returns the Grouping for an Assignment with id 'aid' if this Student has
  # a Membership in that Grouping where the membership.status is 'accepted'
  # or 'inviter'
  def accepted_grouping_for(aid)
    return accepted_groupings.find_by_assignment_id(aid)
  end
  
  def has_pending_groupings_for?(aid)
    return (pending_groupings_for(aid).size > 0)
  end
  
  def pending_groupings_for(aid)
    return pending_groupings.find_all_by_assignment_id(aid)
  end

  # return pending memberships for a specific assignment
  def pending_memberships_for(aid)
    groupings = self.pending_groupings_for(aid)
    if !groupings.nil?
      pending_memberships = []
      groupings.each do |grouping|
         pending_memberships.push(StudentMembership.find_by_grouping_id_and_user_id(grouping.id, self.id))
      end
      return pending_memberships
    end
    return nil
  end

  # Returns the Membership for a Grouping for an Assignment with id 'aid' if 
  # this Student is a member with either 'accepted' or 'invitier' membership
  # status

  def  memberships_for(aid)
     @student = self
     @memberships = StudentMembership.find(:all, :conditions => {:user_id => @student.id})
     @memberships.each do |m|
        if m.grouping.assignment_id != aid
          @memberships.delete(m)
        end
     end
     return @memberships
  end
  

  def invite(gid)
    membership = StudentMembership.new
    membership.grouping_id = gid;
    membership.membership_status = StudentMembership::STATUSES[:pending]
    membership.user_id = self.id
    membership.save
  end


  # creates a group and a grouping for a student to work alone, for
  # assignment aid
  def create_group_for_working_alone_student(aid)
    @assignment = Assignment.find(aid)
    @grouping = Grouping.new
    @grouping.assignment_id = @assignment.id
    if Group.find(:first, :conditions => {:group_name => self.user_name})
      @group = Group.find(:first, :conditions => {:group_name => self.user_name})
    else
      @group = Group.new(:group_name => self.user_name)
      @group.save
    end
    @grouping.group = @group
    @grouping.save

    # Create the membership
    @member = StudentMembership.new(:grouping_id => @grouping.id,
    :membership_status => StudentMembership::STATUSES[:inviter], :user_id => self.id)
    @member.save
  end

  def join(gid)
    membership = StudentMembership.find_by_grouping_id_and_user_id(gid, self.id)
    membership.membership_status = 'accepted'
    membership.save

    grouping = Grouping.find(gid)

    other_memberships = self.pending_memberships_for(grouping.assignment_id)
    other_memberships.each do |m|
      m.membership_status = 'rejected'
      m.save
    end

  end

end

