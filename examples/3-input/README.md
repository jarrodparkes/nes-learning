# Input

In this example, we will detect inputs from a controller. We will use an elegant subroutine for handling continuous and press inputs. Continuous inputs are helpful for features like character movement. For example, "move the player forward as long as the right button is being held down". Press inputs are helpful for situations where an action is only applied once per press like Mario jumping.

## Instructions

```bash
# build example
nesasm input.asm

# run example
Nestopia input.nes

# build and run example
./build-and-run.sh
```
