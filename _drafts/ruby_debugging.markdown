# Two Ruby debugging techniques I regularly use

When working with Ruby in production you’ll yourself in situations where something is going wrong, but you have no clue what. This is a tiny blogpost illustrating two things I regularly do in these situations.

## Using strace to get an impression what the process is doing

```ruby 
loop do
  puts “I am stuck in a loop”
  sleep 2
end
```

looks like that in strace

## Getting a Ruby backtrace

