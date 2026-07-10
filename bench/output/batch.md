Benchmark

Benchmark run from 2026-07-10 16:26:42.223612Z UTC

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
    <td style="white-space: nowrap">batch 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">454.35</td>
    <td style="white-space: nowrap; text-align: right">2.20 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2.71%</td>
    <td style="white-space: nowrap; text-align: right">2.20 ms</td>
    <td style="white-space: nowrap; text-align: right">2.38 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">414.61</td>
    <td style="white-space: nowrap; text-align: right">2.41 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;4.96%</td>
    <td style="white-space: nowrap; text-align: right">2.40 ms</td>
    <td style="white-space: nowrap; text-align: right">2.72 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">43.30</td>
    <td style="white-space: nowrap; text-align: right">23.10 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3.13%</td>
    <td style="white-space: nowrap; text-align: right">22.95 ms</td>
    <td style="white-space: nowrap; text-align: right">26.40 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">38.97</td>
    <td style="white-space: nowrap; text-align: right">25.66 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;3.82%</td>
    <td style="white-space: nowrap; text-align: right">25.61 ms</td>
    <td style="white-space: nowrap; text-align: right">29.04 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">3.90</td>
    <td style="white-space: nowrap; text-align: right">256.28 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1.97%</td>
    <td style="white-space: nowrap; text-align: right">257.24 ms</td>
    <td style="white-space: nowrap; text-align: right">262.91 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">3.50</td>
    <td style="white-space: nowrap; text-align: right">285.50 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2.60%</td>
    <td style="white-space: nowrap; text-align: right">287.79 ms</td>
    <td style="white-space: nowrap; text-align: right">295.11 ms</td>
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
    <td style="white-space: nowrap;text-align: right">454.35</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap; text-align: right">414.61</td>
    <td style="white-space: nowrap; text-align: right">1.1x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">43.30</td>
    <td style="white-space: nowrap; text-align: right">10.49x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap; text-align: right">38.97</td>
    <td style="white-space: nowrap; text-align: right">11.66x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">3.90</td>
    <td style="white-space: nowrap; text-align: right">116.44x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap; text-align: right">3.50</td>
    <td style="white-space: nowrap; text-align: right">129.72x</td>
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
    <td style="white-space: nowrap">1.75 MB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 100 passwords</td>
    <td style="white-space: nowrap">1.69 MB</td>
    <td>0.97x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">batch 1000 passwords</td>
    <td style="white-space: nowrap">17.52 MB</td>
    <td>10.01x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 1000 passwords</td>
    <td style="white-space: nowrap">16.95 MB</td>
    <td>9.68x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">individual 10000 passwords</td>
    <td style="white-space: nowrap">169.54 MB</td>
    <td>96.84x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">batch 10000 passwords</td>
    <td style="white-space: nowrap">175.32 MB</td>
    <td>100.14x</td>
  </tr>
</table>