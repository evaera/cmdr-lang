# cmdr-lang

The language parser backing Cmdr v2.

## Grammar example

```
cmd string_arg string_arg rest string arg

$variable = 5

cmd string $variable here; cmd 1234

cmd string {expr}

# cmd list,example
# cmd "li,st",example
# cmd (list, example)

if 1 == 2 {

} elif 3 == 4{

} else {

}

while 1 == 2 {
	# do stuff
}

func die
	victim player Victim The reason we're here
	param2 string Reason The reason you did it
{
	kill $victim
	message $reason
}
```

Todo:
 - Lists
 - Functions
 - Loops
 - Interpreter


## ast example

```json
[
  {
    "args": [
      {
        "type": "str",
        "value": "string_arg"
      },
      {
        "type": "str",
        "value": "string_arg"
      },
      {
        "type": "str",
        "value": "rest"
      },
      {
        "type": "str",
        "value": "string"
      },
      {
        "type": "str",
        "value": "arg"
      }
    ],
    "func": {
      "type": "str",
      "value": "cmd"
    },
    "type": "call"
  },
  {
    "operator": "=",
    "left": {
      "type": "var",
      "value": "variable"
    },
    "type": "assign",
    "right": {
      "type": "num",
      "value": 5
    }
  },
  {
    "args": [
      {
        "type": "str",
        "value": "string"
      },
      {
        "type": "var",
        "value": "variable"
      },
      {
        "type": "str",
        "value": "here"
      }
    ],
    "func": {
      "type": "str",
      "value": "cmd"
    },
    "type": "call"
  },
  {
    "args": [
      {
        "type": "num",
        "value": 1234
      }
    ],
    "func": {
      "type": "str",
      "value": "cmd"
    },
    "type": "call"
  },
  {
    "args": [
      {
        "type": "str",
        "value": "string"
      },
      {
        "type": "prog",
        "prog": [
          {
            "type": "str",
            "value": "expr"
          }
        ]
      }
    ],
    "func": {
      "type": "str",
      "value": "cmd"
    },
    "type": "call"
  },
  {
    "thenBranch": {
      "type": "prog",
      "prog": []
    },
    "condition": {
      "operator": "==",
      "left": {
        "type": "num",
        "value": 1
      },
      "type": "binary",
      "right": {
        "type": "num",
        "value": 2
      }
    },
    "type": "if"
  }
]
```