# matlab-jsystem

***A fast drop-in replacement for matlab's `system` command.***

Ever need to run a shell command or external process from matlab code?
Using matlab's built in `system` command can be extremely slow, causing severe overhead if you're calling it many times.
`jsystem` is a drop-in replacement for `system` which is both much faster and also has some extra convenience features.

## Usage
- Run any shell command:
  ```
  >> [res, out] = jsystem('ls -R')
  res =
       0
  out =
       LICENSE.md
       README.md
       src

       ./src:
       jsystem.m
  ```

- Use shell built-ins, pipes and redirects:
  ```
  >> [res, out] = jsystem('echo "YES" && ls -al | grep src > /dev/null')
  res =
       0
  out =
       YES
  ```

- Specify your own custom shell to use:
  ```
  >> [res, out] = jsystem('echo "My shell is $SHELL"', '/usr/local/bin/zsh')
  res =
       0
  out =
       My shell is /usr/local/bin/zsh
  ```

- Execute a program directly, without a shell (even faster, since there's no shell startup overhead)
  ```
  >> [res, out] = jsystem('/usr/bin/du -h ./src', 'noshell')
  res =
       0
  out =
       4.0K   ./src
  ```

## Benchmarks
Run the included benchmarks in `test/jsystem_benchmak.m` to get an indication of the speedup you can expect to see when using `jsystem`.
Here's a representative result (on my machine - late 2012 macbook pro).

* `jsystem` vs matlab's built-in `system`:
  > Benchmark #1 - Command: "echo OK > /dev/null", 50 iterations <br>
  > **system**: 17.000 [ms] average <br>
  > **jsystem**: 3.400 [ms] average

* `jsystem` with and without a shell
  > Benchmark #2 - Command: "/bin/ls -al", 50 iterations <br>
  > **jsystem**:           3.600 [ms] average <br>
  > **jsystem (noshell)**: 2.600 [ms] average

## Contributing
PRs would be greatly appreciated.

## License
MIT.
