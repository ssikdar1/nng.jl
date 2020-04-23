# NNG.jl

Wrapper julia libraries for nanomsg (https://nanomsg.org/) and nng (https://nng.nanomsg.org/).
Mainly as a learning excercise for myself.

## Setup

### Building libraries

### nng
You can find the nng github repository [here](https://github.com/nanomsg/nng).
The build instructions will result in a shared `.a` file. To create  `libnng.dylib`
add `-DBUILD_SHARED_LIBS=ON ` to the CMake command:
```
cmake -DBUILD_SHARED_LIBS=ON  -G Ninja ..
```

#### Nanomsg
The Nanomsg library can be found [here](https://github.com/nanomsg/nanomsg).

### Linking
For julia to be able to load the dynamic library, the `DYLD_LIBRARY_PATH` enviroment variable must be set to the location of the `dylib`s.
For example on Mac:
```
export DYLD_LIBRARY_PATH="/usr/local/lib/libnanomsg.dylib: /usr/local/lib/libnng.dylib"
```
and to verify in Julia:
```
julia> ENV["DYLD_LIBRARY_PATH"]
"/usr/local/lib/libnanomsg.dylib: /usr/local/lib/libnng.dylib"
```

## Examples

## TODO
- [] basic library
- [] Examples
- [] Julia Module

- For both nng and nanomsg wrappers to get the exmaples working
- [] Pipeline (A One-Way Pipe)
- [] Request/Reply (I ask, you answer)
- [] Pair (Two Way Radio)
- [] Pub/Sub (Topics & Broadcast)
- [] Survey (Everybody Votes)
- [] Bus (Routing)

# LICENSE
Keeping in spirit with both nng and nanomsg this project is  licensed under the MIT License.
