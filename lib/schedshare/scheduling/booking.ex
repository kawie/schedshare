defmodule Schedshare.Scheduling.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    belongs_to :schedule, Schedshare.Scheduling.Schedule

    field :external_id, :integer
    field :status, :string

    # Course fields
    field :course_external_id, :integer
    field :course_date, :date
    field :course_title, :string
    field :is_online, :boolean, default: false
    field :course_types, {:array, :string}
    field :start_time, :time
    field :end_time, :time
    field :start_datetime_utc, :utc_datetime
    field :end_datetime_utc, :utc_datetime

    # Venue fields
    field :venue_external_id, :integer
    field :venue_name, :string
    field :venue_lat, :float
    field :venue_long, :float
    field :venue_full_address, :string
    field :city_name, :string
    field :district_name, :string
    field :booking_type, :string
    field :external, :boolean, default: true
    field :service_type, :string

    # Category fields
    field :category_external_id, :integer
    field :category_name, :string

    # Teacher
    field :teacher_name, :string

    timestamps()
  end

  @doc false
  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :schedule_id,
      :external_id,
      :status,
      :course_external_id,
      :course_date,
      :course_title,
      :is_online,
      :course_types,
      :start_time,
      :end_time,
      :start_datetime_utc,
      :end_datetime_utc,
      :venue_external_id,
      :venue_name,
      :venue_lat,
      :venue_long,
      :venue_full_address,
      :city_name,
      :district_name,
      :booking_type,
      :external,
      :service_type,
      :category_external_id,
      :category_name,
      :teacher_name
    ])
    |> validate_required([
      :schedule_id,
      :external_id,
      :status,
      :course_title,
      :start_datetime_utc,
      :end_datetime_utc
    ])
    |> foreign_key_constraint(:schedule_id)
  end
end
