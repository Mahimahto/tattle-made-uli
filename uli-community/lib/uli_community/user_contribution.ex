defmodule UliCommunity.UserContribution do
  @moduledoc """
  The UserContribution context.
  """

  import Ecto.Query, warn: false
  alias UliCommunity.Repo

  alias UliCommunity.UserContribution.CrowdsourcedSlur

  @doc """
  Returns the list of crowdsourced_slurs.

  ## Examples

      iex> list_crowdsourced_slurs()
      [%CrowdsourcedSlur{}, ...]

  """
  def list_crowdsourced_slurs do
    Repo.all(CrowdsourcedSlur)
  end

  @doc """
  Gets a single crowdsourced_slur.

  Raises `Ecto.NoResultsError` if the Crowdsourced slur does not exist.

  ## Examples

      iex> get_crowdsourced_slur!(123)
      %CrowdsourcedSlur{}

      iex> get_crowdsourced_slur!(456)
      ** (Ecto.NoResultsError)

  """
  def get_crowdsourced_slur!(id), do: Repo.get!(CrowdsourcedSlur, id)

  @doc """
  Creates a crowdsourced_slur.

  ## Examples

      iex> create_crowdsourced_slur(%{field: value})
      {:ok, %CrowdsourcedSlur{}}

      iex> create_crowdsourced_slur(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_crowdsourced_slur(attrs \\ %{}) do
    %CrowdsourcedSlur{}
    |> CrowdsourcedSlur.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, slur} ->
        Phoenix.PubSub.broadcast(UliCommunity.PubSub, "crowdsourced_slurs", {:new_slur, slur})
        {:ok, slur}

      error ->
        error
    end
  end

  def create_crowdsourced_slur_with_label(attrs \\ %{}) do
    %CrowdsourcedSlur{}
    |> CrowdsourcedSlur.changeset_only_label(attrs)
    |> Repo.insert()
    |> case do
      {:ok, slur} ->
        Phoenix.PubSub.broadcast(UliCommunity.PubSub, "crowdsourced_slurs", {:new_slur, slur})
        {:ok, slur}

      error ->
        error
    end
  end

  def create_crowdsourced_slur_seed(attrs \\ %{}) do
    %CrowdsourcedSlur{}
    |> CrowdsourcedSlur.changeset_seed(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a crowdsourced_slur.

  ## Examples

      iex> update_crowdsourced_slur(crowdsourced_slur, %{field: new_value})
      {:ok, %CrowdsourcedSlur{}}

      iex> update_crowdsourced_slur(crowdsourced_slur, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_crowdsourced_slur(%CrowdsourcedSlur{} = crowdsourced_slur, attrs) do
    crowdsourced_slur
    |> CrowdsourcedSlur.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a crowdsourced_slur.

  ## Examples

      iex> delete_crowdsourced_slur(crowdsourced_slur)
      {:ok, %CrowdsourcedSlur{}}

      iex> delete_crowdsourced_slur(crowdsourced_slur)
      {:error, %Ecto.Changeset{}}

  """
  def delete_crowdsourced_slur(%CrowdsourcedSlur{} = crowdsourced_slur) do
    Repo.delete(crowdsourced_slur)
    |> case do
      {:ok, slur} ->
        Phoenix.PubSub.broadcast(UliCommunity.PubSub, "crowdsourced_slurs", {:deleted_slur, slur})
        {:ok, slur}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking crowdsourced_slur changes.

  ## Examples

      iex> change_crowdsourced_slur(crowdsourced_slur)
      %Ecto.Changeset{data: %CrowdsourcedSlur{}}

  """
  def change_crowdsourced_slur(%CrowdsourcedSlur{} = crowdsourced_slur, attrs \\ %{}) do
    CrowdsourcedSlur.changeset(crowdsourced_slur, attrs)
  end

  def get_crowdsourced_slur_by_user(contributor_user_id) do
    slurs =
      Repo.all(from(s in CrowdsourcedSlur, where: s.contributor_user_id == ^contributor_user_id))

    {:ok, slurs}
  end

  def get_top_slurs(n) when is_integer(n) and n > 0 do
    CrowdsourcedSlur
    |> group_by([s], fragment("lower(?)", s.label))
    |> select([s], %{label: fragment("lower(?)", s.label), count: count(s.id)})
    |> order_by([_s], desc: count(fragment("lower(?)", ^"label")))
    |> limit(^n)
    |> Repo.all()
  end

  def get_severity_distribution do
    UliCommunity.UserContribution.CrowdsourcedSlur
    |> group_by([s], s.level_of_severity)
    |> select([s], %{label: s.level_of_severity, count: count(s.id)})
    |> Repo.all()
  end

  def get_source_distribution do
    CrowdsourcedSlur
    |> group_by([s], s.source)
    |> select([s], %{source: s.source, count: count(s.id)})
    |> Repo.all()
  end

 def get_weekly_submission_counts do
  weekly_data =
    Repo.all(
      from(cs in CrowdsourcedSlur,
        where: not is_nil(cs.inserted_at),
        group_by: fragment("date_trunc('week', ?)", cs.inserted_at),
        order_by: fragment("date_trunc('week', ?)", cs.inserted_at),
        select: %{
          week_start: fragment("date_trunc('week', ?)", cs.inserted_at),
          count: count(cs.id)
        }
      )
    )

  Enum.map(weekly_data, fn %{week_start: week_start, count: count} ->
    %{
      week_start_date: to_iso_date(week_start),
      count: count
    }
  end)
end

defp to_iso_date(naive_date) do
  naive_date
  |> NaiveDateTime.to_date()
  |> Date.to_iso8601()
end

end
