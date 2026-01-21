Benchmark

Benchmark run from 2026-01-21 11:05:43.748585Z UTC

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
    <td style="white-space: nowrap">1.19.5</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">28.2</td>
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
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">size() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">275.32 M</td>
    <td style="white-space: nowrap; text-align: right">3.63 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3881.91%</td>
    <td style="white-space: nowrap; text-align: right">4.20 ns</td>
    <td style="white-space: nowrap; text-align: right">8.30 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">max_length() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">272.08 M</td>
    <td style="white-space: nowrap; text-align: right">3.68 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3759.72%</td>
    <td style="white-space: nowrap; text-align: right">4.20 ns</td>
    <td style="white-space: nowrap; text-align: right">8.30 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">min_length() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">39.35 M</td>
    <td style="white-space: nowrap; text-align: right">25.41 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;136.96%</td>
    <td style="white-space: nowrap; text-align: right">41 ns</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">all() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">38.80 M</td>
    <td style="white-space: nowrap; text-align: right">25.77 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;201.07%</td>
    <td style="white-space: nowrap; text-align: right">41 ns</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">23.74 M</td>
    <td style="white-space: nowrap; text-align: right">42.12 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1060.53%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">83 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">23.64 M</td>
    <td style="white-space: nowrap; text-align: right">42.31 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1399.66%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">83 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap; text-align: right">23.34 M</td>
    <td style="white-space: nowrap; text-align: right">42.85 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1138.26%</td>
    <td style="white-space: nowrap; text-align: right">42 ns</td>
    <td style="white-space: nowrap; text-align: right">83 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap; text-align: right">5.23 M</td>
    <td style="white-space: nowrap; text-align: right">191.30 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1713.05%</td>
    <td style="white-space: nowrap; text-align: right">167 ns</td>
    <td style="white-space: nowrap; text-align: right">250 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">5.21 M</td>
    <td style="white-space: nowrap; text-align: right">191.81 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1696.84%</td>
    <td style="white-space: nowrap; text-align: right">167 ns</td>
    <td style="white-space: nowrap; text-align: right">250 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">5.14 M</td>
    <td style="white-space: nowrap; text-align: right">194.70 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1733.01%</td>
    <td style="white-space: nowrap; text-align: right">167 ns</td>
    <td style="white-space: nowrap; text-align: right">291 ns</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">size() - O(1)</td>
    <td style="white-space: nowrap;text-align: right">275.32 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">max_length() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">272.08 M</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">min_length() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">39.35 M</td>
    <td style="white-space: nowrap; text-align: right">7.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">all() - O(1)</td>
    <td style="white-space: nowrap; text-align: right">38.80 M</td>
    <td style="white-space: nowrap; text-align: right">7.1x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">23.74 M</td>
    <td style="white-space: nowrap; text-align: right">11.6x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">23.64 M</td>
    <td style="white-space: nowrap; text-align: right">11.65x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap; text-align: right">23.34 M</td>
    <td style="white-space: nowrap; text-align: right">11.8x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap; text-align: right">5.23 M</td>
    <td style="white-space: nowrap; text-align: right">52.67x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap; text-align: right">5.21 M</td>
    <td style="white-space: nowrap; text-align: right">52.81x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">5.14 M</td>
    <td style="white-space: nowrap; text-align: right">53.6x</td>
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
    <td style="white-space: nowrap">size() - O(1)</td>
    <td style="white-space: nowrap">0 B</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">max_length() - O(1)</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">min_length() - O(1)</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">all() - O(1)</td>
    <td style="white-space: nowrap">0 B</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(3, 10)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(4, 8)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">count_between(3, 5)</td>
    <td style="white-space: nowrap">24 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(4, 6)</td>
    <td style="white-space: nowrap">48 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(3, 10)</td>
    <td style="white-space: nowrap">48.00 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">random_word_between(4, 8)</td>
    <td style="white-space: nowrap">48 B</td>
    <td>&mdash;</td>
  </tr>
</table>