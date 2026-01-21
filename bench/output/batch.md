Benchmark

Benchmark run from 2026-01-21 11:07:02.895889Z UTC

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
    <td style="white-space: nowrap">batch 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">4060.91</td>
    <td style="white-space: nowrap; text-align: right">0.25 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.83%</td>
    <td style="white-space: nowrap; text-align: right">0.24 ms</td>
    <td style="white-space: nowrap; text-align: right">0.34 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">3245.16</td>
    <td style="white-space: nowrap; text-align: right">0.31 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.37%</td>
    <td style="white-space: nowrap; text-align: right">0.30 ms</td>
    <td style="white-space: nowrap; text-align: right">0.42 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">366.27</td>
    <td style="white-space: nowrap; text-align: right">2.73 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3.69%</td>
    <td style="white-space: nowrap; text-align: right">2.72 ms</td>
    <td style="white-space: nowrap; text-align: right">2.98 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">282.97</td>
    <td style="white-space: nowrap; text-align: right">3.53 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3.70%</td>
    <td style="white-space: nowrap; text-align: right">3.51 ms</td>
    <td style="white-space: nowrap; text-align: right">3.92 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">26.49</td>
    <td style="white-space: nowrap; text-align: right">37.75 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1.80%</td>
    <td style="white-space: nowrap; text-align: right">37.74 ms</td>
    <td style="white-space: nowrap; text-align: right">40.82 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">24.90</td>
    <td style="white-space: nowrap; text-align: right">40.17 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1.94%</td>
    <td style="white-space: nowrap; text-align: right">40.03 ms</td>
    <td style="white-space: nowrap; text-align: right">45.46 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">batch 100 passwords</td>
    <td style="white-space: nowrap;text-align: right">4060.91</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">3245.16</td>
    <td style="white-space: nowrap; text-align: right">1.25x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">366.27</td>
    <td style="white-space: nowrap; text-align: right">11.09x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">282.97</td>
    <td style="white-space: nowrap; text-align: right">14.35x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">26.49</td>
    <td style="white-space: nowrap; text-align: right">153.28x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">24.90</td>
    <td style="white-space: nowrap; text-align: right">163.12x</td>
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
    <td style="white-space: nowrap">batch 100 passwords</td>
    <td style="white-space: nowrap">0.80 MB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap">0.74 MB</td>
    <td>0.93x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap">7.96 MB</td>
    <td>10.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap">7.44 MB</td>
    <td>9.34x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap">74.38 MB</td>
    <td>93.38x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap">79.63 MB</td>
    <td>99.97x</td>
  </tr>
</table>