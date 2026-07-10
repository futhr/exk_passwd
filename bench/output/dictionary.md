Benchmark

Benchmark run from 2026-07-10 16:25:47.339747Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M4 Max</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">16</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">128 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.20.2</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">29.0.3</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Deviation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">all()</td>
    <td style="white-space: nowrap; text-align: right">465.30 M</td>
    <td style="white-space: nowrap; text-align: right">2.15 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;83.33%</td>
    <td style="white-space: nowrap; text-align: right">2.13 ns</td>
    <td style="white-space: nowrap; text-align: right">2.79 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">size()</td>
    <td style="white-space: nowrap; text-align: right">461.95 M</td>
    <td style="white-space: nowrap; text-align: right">2.16 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;71.39%</td>
    <td style="white-space: nowrap; text-align: right">2.17 ns</td>
    <td style="white-space: nowrap; text-align: right">2.75 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">min_length()</td>
    <td style="white-space: nowrap; text-align: right">460.89 M</td>
    <td style="white-space: nowrap; text-align: right">2.17 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;65.84%</td>
    <td style="white-space: nowrap; text-align: right">2.17 ns</td>
    <td style="white-space: nowrap; text-align: right">2.79 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">max_length()</td>
    <td style="white-space: nowrap; text-align: right">258.54 M</td>
    <td style="white-space: nowrap; text-align: right">3.87 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;4178.65%</td>
    <td style="white-space: nowrap; text-align: right">4.20 ns</td>
    <td style="white-space: nowrap; text-align: right">8.30 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap; text-align: right">22.64 M</td>
    <td style="white-space: nowrap; text-align: right">44.16 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1027.19%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">84 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">22.50 M</td>
    <td style="white-space: nowrap; text-align: right">44.44 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;963.03%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">84 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">22.42 M</td>
    <td style="white-space: nowrap; text-align: right">44.59 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1039.86%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">84 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">4.28 M</td>
    <td style="white-space: nowrap; text-align: right">233.41 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;537.09%</td>
    <td style="white-space: nowrap; text-align: right">209 ns</td>
    <td style="white-space: nowrap; text-align: right">417 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap; text-align: right">4.27 M</td>
    <td style="white-space: nowrap; text-align: right">234.27 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1780.01%</td>
    <td style="white-space: nowrap; text-align: right">208 ns</td>
    <td style="white-space: nowrap; text-align: right">375 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">4.16 M</td>
    <td style="white-space: nowrap; text-align: right">240.20 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1089.52%</td>
    <td style="white-space: nowrap; text-align: right">209 ns</td>
    <td style="white-space: nowrap; text-align: right">417 ns</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">all()</td>
    <td style="white-space: nowrap;text-align: right">465.30 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">size()</td>
    <td style="white-space: nowrap; text-align: right">461.95 M</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">min_length()</td>
    <td style="white-space: nowrap; text-align: right">460.89 M</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">max_length()</td>
    <td style="white-space: nowrap; text-align: right">258.54 M</td>
    <td style="white-space: nowrap; text-align: right">1.8x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap; text-align: right">22.64 M</td>
    <td style="white-space: nowrap; text-align: right">20.55x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">22.50 M</td>
    <td style="white-space: nowrap; text-align: right">20.68x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">22.42 M</td>
    <td style="white-space: nowrap; text-align: right">20.75x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">4.28 M</td>
    <td style="white-space: nowrap; text-align: right">108.61x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap; text-align: right">4.27 M</td>
    <td style="white-space: nowrap; text-align: right">109.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">4.16 M</td>
    <td style="white-space: nowrap; text-align: right">111.76x</td>
  </tr>

</table>



Memory Usage

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Factor</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">all()</td>
    <td style="white-space: nowrap">0 B</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">size()</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">min_length()</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">max_length()</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap">73.30 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap">72.73 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap">73.65 B</td>
    <td>&mdash;</td>
  </tr>
</table>