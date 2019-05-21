# Poker hand value

A library to rate and compare poker hands. Any hand with 5 or more cards can be rated and is therefore suitable for texas hold em and other > 5 card poker types.

## Example
```elixir
hand = "As Ad Ac Js Jd"
PokerHandValue.rate_hand(hand) # => {:full_house, 7.1411}

hand2 = "2c 3d 4h 5s 6c"
PokerHandValue.rate_hand(hand2) # => {:straight, 5.06}

PokerHandValue.compare_hands(hand, hand2) # => :gt
```

## Installation

```elixir
def deps do
  [
    {:poker_hand_value, "~> 0.1.0"}
  ]
end
```


