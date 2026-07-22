class Ticket < ApplicationRecord
  ATTENDED_STATUS = "attended".freeze

  PUBLIC_SCREEN_ACTIVE_STATUSES = %w[
    called
    in_attention
  ].freeze

  STATUSES = %w[
    pending
    called
    in_attention
    attended
    no_show
    cancelled
  ].freeze

  PRIORITY_WEIGHTS = {
    "emergency" => 1,
    "disability" => 2,
    "senior" => 3,
    "pregnancy" => 4,
    "appointment" => 5,
    "normal" => 6
  }.freeze

  INTAKE_SOURCES = %w[
    self_service
    assisted
  ].freeze

  ASSISTANCE_TYPES = %w[
    disability
    senior
    pregnancy
    appointment
  ].freeze

  scope :with_public_screen_associations, lambda {
    includes(
      :queue_service,
      :service_window,
      :assigned_agent
    )
  }

  scope :recently_called_for_public_screen, lambda {
    with_public_screen_associations
      .where.not(called_at: nil)
      .order(called_at: :desc, id: :desc)
  }

  scope :active_for_public_screen, lambda {
    recently_called_for_public_screen
      .where(status: PUBLIC_SCREEN_ACTIVE_STATUSES)
  }

  belongs_to :queue_service
  belongs_to :service_window, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :assigned_agent, class_name: "User", optional: true

  has_one :satisfaction_survey,
          dependent: :restrict_with_exception

  has_secure_token :survey_token

  validates :survey_token,
            presence: true,
            uniqueness: true

  validates :ticket_number,
            presence: true,
            uniqueness: { scope: :sequence_date }

  validates :sequence_date, presence: true

  validates :daily_sequence,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :priority,
            presence: true,
            inclusion: { in: PRIORITY_WEIGHTS.keys }

  validates :priority_weight,
            presence: true,
            inclusion: { in: PRIORITY_WEIGHTS.values }

  validates :status,
            presence: true,
            inclusion: { in: STATUSES }

  validates :intake_source,
            presence: true,
            inclusion: { in: INTAKE_SOURCES }

  validates :assistance_type,
            inclusion: { in: ASSISTANCE_TYPES },
            allow_nil: true

  validates :queue_service, presence: true

  validate :created_by_required_for_assisted_intake

  private

  def created_by_required_for_assisted_intake
    return unless intake_source == "assisted"
    return if created_by.present?

    errors.add(:created_by, "is required for assisted intake")
  end
end
