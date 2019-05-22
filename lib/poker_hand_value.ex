defmodule PokerHandValue do
  @moduledoc """
  A library to rate and compare poker hands. Any hand with 5 or more cards can be rated and is therefore suitable for texas hold em and other > 5 card poker types.

  ## Example
  ```elixir
  hand = "As Ad Ac Js Jd"
  PokerHandValue.rate_hand(hand) # => {:full_house, 7.1411}

  hand2 = "2c 3d 4h 5s 6c"
  PokerHandValue.rate_hand(hand2) # => {:straight, 5.06}

  PokerHandValue.compare_hands(hand, hand2) # => :gt
  ```

  """

  import List, only: [first: 1, last: 1]
  import Map, only: [values: 1]

  import Enum,
    only: [
      map: 2,
      filter: 2,
      sort: 1,
      take: 2,
      sort_by: 2,
      group_by: 2,
      reverse: 1,
      uniq_by: 2,
      member?: 2,
      reduce: 2
    ]

  @doc """
  Compares two hands. returns :gt if the value of the first hand is greater, :lt if lesses and :eq if they have same value

  ## Examples

      iex> PokerHandValue.compare_hands("Js Jh 2h 2c 3h", "Qs 2c 5h Jh 10s")
      :gt

      iex> PokerHandValue.compare_hands("As Ah Ad 7h 3d", "2h 3h 4h 5h 6h")
      :lt

      iex> PokerHandValue.compare_hands("Ks Kh 2d 2h 3d", "Kc Kd 2c 2s 3c")
      :eq
  """
  def compare_hands(first, second) when is_binary(first),
    do: compare_hands(rate_hand(first), second)

  def compare_hands(first, second) when is_binary(second),
    do: compare_hands(first, rate_hand(second))

  def compare_hands(first, second) do
    {_, first} = first
    {_, second} = second

    cond do
      first > second -> :gt
      second > first -> :lt
      first === second -> :eq
    end
  end

  @doc """
  Converts a hand to a rating

  ## Examples

      iex> PokerHandValue.rate_hand("Qh Jh 2h 7h 3h")
      {:flush, 6.1211070302}

      iex> PokerHandValue.rate_hand("As Ah Ad 7h 3d")
      {:three_of_a_kind, 4.140703}

      iex> PokerHandValue.rate_hand("As Ah Kd 2h 3d")
      {:pair, 2.14130302}
  """
  def rate_hand(hand) when is_binary(hand), do: rate_hand(parse_hand(hand))

  def rate_hand(hand) do
    case get_best_hand(hand, get_hands()) do
      {:straight_flush, score} -> {:straight_flush, 9 + score}
      {:four_of_a_kind, score} -> {:four_of_a_kind, 8 + score}
      {:full_house, score} -> {:full_house, 7 + score}
      {:flush, score} -> {:flush, 6 + score}
      {:straight, score} -> {:straight, 5 + score}
      {:three_of_a_kind, score} -> {:three_of_a_kind, 4 + score}
      {:two_pair, score} -> {:two_pair, 3 + score}
      {:pair, score} -> {:pair, 2 + score}
      {:high_card, score} -> {:high_card, 1 + score}
    end
  end

  @doc """
  Matches every hand

  ## Examples

      iex> PokerHandValue.match_high_card([{:hearts, 4}, {:diamonds, 2}, {:spades, 9}, {:hearts, 11}, {:diamonds, 3}])
      {:high_card, 0.1109040302}

      iex> PokerHandValue.match_high_card([{:hearts, 4}, {:diamonds, 2}, {:spades, 9}, {:hearts, 11}, {:diamonds, 3}, {:clubs, 12}])
      {:high_card, 0.1211090403}
  """
  def match_high_card(hand) when is_binary(hand), do: match_high_card(parse_hand(hand))

  def match_high_card(hand) do
    hand
    |> remove_suits
    |> sort()
    |> reverse()
    |> take(5)
    |> count_score(:high_card)
  end

  @doc """
  Matches a pair

  ## Examples

      iex> PokerHandValue.match_pair([{:hearts, 4}, {:diamonds, 2}, {:spades, 9}, {:hearts, 9}, {:diamonds, 3}])
      {:pair, 0.09040302}

      iex> PokerHandValue.match_pair([{:hearts, 5}, {:diamonds, 2}, {:spades, 13}, {:hearts, 13}, {:diamonds, 3}])
      {:pair, 0.13050302}

      iex> PokerHandValue.match_pair([{:hearts, 5}, {:diamonds, 2}, {:spades, 13}, {:hearts, 13}, {:diamonds, 3}, {:clubs, 7}])
      {:pair, 0.13070503}

      iex> PokerHandValue.match_pair([{:hearts, 5}, {:diamonds, 2}, {:spades, 13}, {:hearts, 7}, {:diamonds, 3}])
      nil
  """
  def match_pair(hand) when is_binary(hand), do: match_pair(parse_hand(hand))

  def match_pair(hand) do
    hand = remove_suits(hand)

    pair = get_highest_pair(hand)

    cond do
      pair != nil ->
        count_score([pair | remove_cards_from_hand(hand, pair) |> take(3)], :pair)

      true ->
        nil
    end
  end

  @doc """
  Matches two pairs

  ## Examples

      iex> PokerHandValue.match_two_pair([{:hearts, 4}, {:diamonds, 4}, {:spades, 9}, {:hearts, 6}, {:diamonds, 6}])
      {:two_pair, 0.060409}

      iex> PokerHandValue.match_two_pair([{:hearts, 4}, {:diamonds, 4}, {:spades, 9}, {:hearts, 6}, {:diamonds, 6}, {:hearts, 2}])
      {:two_pair, 0.060409}

      iex> PokerHandValue.match_two_pair([{:hearts, 4}, {:diamonds, 2}, {:spades, 9}, {:hearts, 6}, {:diamonds, 6}])
      nil

      iex> PokerHandValue.match_two_pair([{:hearts, 4}, {:diamonds, 2}, {:spades, 9}, {:hearts, 10}, {:diamonds, 6}])
      nil
  """
  def match_two_pair(hand) when is_binary(hand), do: match_two_pair(parse_hand(hand))

  def match_two_pair(hand) do
    hand = remove_suits(hand)

    pair = get_highest_pair(hand)
    hand = remove_cards_from_hand(hand, pair)
    second_pair = get_highest_pair(hand)
    hand = remove_cards_from_hand(hand, second_pair)

    cond do
      pair != nil && second_pair != nil ->
        count_score([pair, second_pair] ++ [first(hand)], :two_pair)

      true ->
        nil
    end
  end

  @doc """
  Matches three of a kind

  ## Examples

      iex> PokerHandValue.match_three_of_a_kind([{:hearts, 12}, {:diamonds, 12}, {:spades, 12}, {:hearts, 3}, {:diamonds, 6}])
      {:three_of_a_kind, 0.120603}

      iex> PokerHandValue.match_three_of_a_kind([{:hearts, 12}, {:diamonds, 12}, {:spades, 12}, {:hearts, 3}, {:diamonds, 6}, {:spades, 2}])
      {:three_of_a_kind, 0.120603}

      iex> PokerHandValue.match_three_of_a_kind([{:hearts, 12}, {:diamonds, 12}, {:spades, 10}, {:hearts, 3}, {:diamonds, 6}])
      nil

      iex> PokerHandValue.match_three_of_a_kind([{:hearts, 12}, {:diamonds, 10}, {:spades, 9}, {:hearts, 3}, {:diamonds, 6}])
      nil

  """
  def match_three_of_a_kind(hand) when is_binary(hand),
    do: match_three_of_a_kind(parse_hand(hand))

  def match_three_of_a_kind(hand) do
    hand = remove_suits(hand)

    three_of_a_kind = get_highest_three_of_a_kind(hand)

    cond do
      three_of_a_kind != nil ->
        count_score(
          [three_of_a_kind | remove_cards_from_hand(hand, three_of_a_kind) |> take(2)],
          :three_of_a_kind
        )

      true ->
        nil
    end
  end

  @doc """
  Matches a straight

  ## Examples

      iex> PokerHandValue.match_straight([{:hearts, 4}, {:diamonds, 5}, {:spades, 6}, {:hearts, 7}, {:diamonds, 8}])
      {:straight, 0.08}

      iex> PokerHandValue.match_straight([{:hearts, 14}, {:diamonds, 5}, {:spades, 3}, {:hearts, 4}, {:diamonds, 2}])
      {:straight, 0.05}

      iex> PokerHandValue.match_straight([{:hearts, 14}, {:diamonds, 5}, {:spades, 3}, {:hearts, 4}, {:diamonds, 2}, {:spades, 10}])
      {:straight, 0.05}

      iex> PokerHandValue.match_straight([{:hearts, 14}, {:diamonds, 13}, {:spades, 12}, {:hearts, 11}, {:diamonds, 10}])
      {:straight, 0.14}

      iex> PokerHandValue.match_straight([{:hearts, 13}, {:diamonds, 5}, {:spades, 9}, {:hearts, 7}, {:diamonds, 8}])
      nil
  """
  def match_straight(hand) when is_binary(hand), do: match_straight(parse_hand(hand))

  def match_straight(hand) do
    hand = remove_suits(hand)

    hand = prefix_one_if_contains_ace(hand)

    straight_from =
      hand
      |> sort()
      |> take(length(hand) - 4)
      |> filter(&is_straight_from_number!(&1, hand))

    cond do
      length(straight_from) > 0 ->
        count_score([first(straight_from) + 4], :straight)

      true ->
        nil
    end
  end

  @doc """
  Matches a flush

  ## Examples

      iex> PokerHandValue.match_flush([{:hearts, 9}, {:hearts, 11}, {:hearts, 14}, {:hearts, 7}, {:hearts, 3}])
      {:flush, 0.1411090703}

      iex> PokerHandValue.match_flush([{:hearts, 9}, {:hearts, 11}, {:hearts, 14}, {:hearts, 7}, {:hearts, 3}, {:hearts, 2}])
      {:flush, 0.1411090703}

      iex> PokerHandValue.match_flush([{:hearts, 9}, {:diamonds, 11}, {:hearts, 2}, {:spades, 7}, {:hearts, 3}])
      nil

  """
  def match_flush(hand) when is_binary(hand), do: match_flush(parse_hand(hand))

  def match_flush(hand) do
    flush =
      hand
      |> sort_by(fn card -> elem(card, 1) end)
      |> group_by(fn card -> elem(card, 0) end)
      |> values()
      |> filter(fn suit -> length(suit) >= 5 end)
      |> last()

    cond do
      flush != nil ->
        count_score(
          flush |> remove_suits |> sort() |> reverse(),
          :flush
        )

      true ->
        nil
    end
  end

  @doc """
  Matches a full house, specifying the three of a kind value

  ## Examples

      iex> PokerHandValue.match_full_house([{:hearts, 9}, {:diamonds, 9}, {:spades, 9}, {:hearts, 3}, {:diamonds, 3}])
      {:full_house, 0.0903}

      iex> PokerHandValue.match_full_house([{:hearts, 2}, {:diamonds, 9}, {:spades, 9}, {:hearts, 3}, {:diamonds, 3}])
      nil

  """
  def match_full_house(hand) when is_binary(hand), do: match_full_house(parse_hand(hand))

  def match_full_house(hand) do
    hand = remove_suits(hand)

    three_of_a_kind = get_highest_three_of_a_kind(hand)
    hand = remove_cards_from_hand(hand, three_of_a_kind)
    pair = get_highest_pair(hand)

    cond do
      three_of_a_kind != nil && pair != nil -> count_score([three_of_a_kind, pair], :full_house)
      true -> nil
    end
  end

  @doc """
  Matches four of a kind, specifying the value

  ## Examples

      iex> PokerHandValue.match_four_of_a_kind([{:hearts, 12}, {:diamonds, 12}, {:spades, 12}, {:hearts, 12}, {:diamonds, 6}])
      {:four_of_a_kind, 0.1206}

      iex> PokerHandValue.match_four_of_a_kind([{:hearts, 12}, {:diamonds, 12}, {:spades, 12}, {:hearts, 12}, {:diamonds, 6}, {:spades, 4}])
      {:four_of_a_kind, 0.1206}

      iex> PokerHandValue.match_four_of_a_kind([{:hearts, 12}, {:diamonds, 11}, {:spades, 12}, {:hearts, 12}, {:diamonds, 6}])
      nil
  """
  def match_four_of_a_kind(hand) when is_binary(hand), do: match_four_of_a_kind(parse_hand(hand))

  def match_four_of_a_kind(hand) do
    hand = remove_suits(hand)

    four_of_a_kind = get_highest_four_of_a_kind(hand)
    hand = remove_cards_from_hand(hand, four_of_a_kind)

    cond do
      four_of_a_kind != nil ->
        count_score([four_of_a_kind] ++ [first(hand)], :four_of_a_kind)

      true ->
        nil
    end
  end

  @doc """
  Matches a straight flush

  ## Examples

      iex> PokerHandValue.match_straight_flush([{:hearts, 9}, {:hearts, 5}, {:hearts, 6}, {:hearts, 7}, {:hearts, 8}])
      {:straight_flush, 0.09}

      iex> PokerHandValue.match_straight_flush([{:hearts, 9}, {:hearts, 5}, {:hearts, 10}, {:hearts, 7}, {:hearts, 8}])
      nil

  """
  def match_straight_flush(hand) when is_binary(hand), do: match_straight_flush(parse_hand(hand))

  def match_straight_flush(hand) do
    straight_flush =
      hand
      |> uniq_by(fn card -> elem(card, 1) end)
      |> group_by(fn card -> elem(card, 0) end)
      |> values()
      |> filter(fn suit -> length(suit) >= 5 end)
      |> map(&match_straight(&1))
      |> filter(&(&1 != nil))

    cond do
      length(straight_flush) > 0 ->
        {:straight_flush, straight_flush |> first() |> elem(1)}

      true ->
        nil
    end
  end

  @doc """
  Matches four of a kind, specifying the value

  ## Examples

      iex> PokerHandValue.parse_hand("Qs 10s 2d Ah 5c")
      [{:spades, 12}, {:spades, 10}, {:diamonds, 2}, {:hearts, 14}, {:clubs, 5}]

      iex> PokerHandValue.parse_hand("Invalid hand")
      ** (RuntimeError) Unable to parse hand
  """
  def parse_hand(hand) do
    hand
    |> String.split()
    |> map(fn card ->
      card_list = card |> String.split_at(-1)

      try do
        {
          lookup(card_list |> elem(1) |> String.upcase()),
          lookup(card_list |> elem(0) |> String.upcase())
        }
      rescue
        _ -> raise "Unable to parse hand"
      end
    end)
  end

  defp lookup("A"), do: 14
  defp lookup("K"), do: 13
  defp lookup("Q"), do: 12
  defp lookup("J"), do: 11
  defp lookup("S"), do: :spades
  defp lookup("D"), do: :diamonds
  defp lookup("H"), do: :hearts
  defp lookup("C"), do: :clubs

  defp lookup(num) do
    String.to_integer(num)
  end

  defp get_method_name(hand) do
    String.to_atom("match_" <> to_string(hand))
  end

  defp get_best_hand(hand, [hand_to_try | all_hands]) when is_list(hand) do
    best_hand = apply(__MODULE__, get_method_name(hand_to_try), [hand])

    cond do
      best_hand != nil -> best_hand
      true -> get_best_hand(hand, all_hands)
    end
  end

  defp is_straight_from_number!(number, hand) do
    length(hand -- make_straight_from(number)) - length(hand) == -5
  end

  defp remove_suits(hand) do
    hand
    |> map(&elem(&1, 1))
    |> sort()
  end

  defp make_two_digit(digit) do
    cond do
      String.length(digit) == 1 -> "0" <> digit
      true -> digit
    end
  end

  defp get_highest_four_of_a_kind(hand) do
    get_highest(hand, 4)
  end

  defp get_highest_three_of_a_kind(hand) do
    get_highest(hand, 3)
  end

  defp get_highest_pair(hand) do
    get_highest(hand, 2)
  end

  defp get_highest(hand, amount) do
    pair =
      hand
      |> group_by(& &1)
      |> values()
      |> filter(&(length(&1) == amount))
      |> last()

    cond do
      is_list(pair) -> first(pair)
      true -> nil
    end
  end

  defp count_score(cards, value) do
    cards
    |> take(5)
    |> map(&Integer.to_string(&1))
    |> map(&make_two_digit(&1))
    |> reduce(fn item, acc -> acc <> item end)
    |> make_fractional
    |> (fn score -> {value, score} end).()
  end

  defp make_fractional(score) do
    import String, only: [to_integer: 1, pad_trailing: 3]

    to_integer(score) / to_integer(pad_trailing("1", String.length(score) + 1, "0"))
  end

  defp remove_cards_from_hand(hand, cards) when cards == nil do
    hand
  end

  defp remove_cards_from_hand(hand, cards) do
    hand
    |> filter(&(&1 != cards))
    |> sort()
    |> reverse()
  end

  defp prefix_one_if_contains_ace(hand) do
    cond do
      member?(hand, 14) -> [1 | hand]
      true -> hand
    end
  end

  defp make_straight_from(num) do
    num..(num + 4)
    |> reverse()
  end

  defp get_hands do
    [
      :straight_flush,
      :four_of_a_kind,
      :full_house,
      :flush,
      :straight,
      :three_of_a_kind,
      :two_pair,
      :pair,
      :high_card
    ]
  end
end
