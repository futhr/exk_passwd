Benchmark

Benchmark run from 2026-07-10 16:25:14.742445Z UTC

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
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap; text-align: right">34348.48 K</td>
    <td style="white-space: nowrap; text-align: right">0.0291 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;120.78%</td>
    <td style="white-space: nowrap; text-align: right">0.0410 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.0420 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap; text-align: right">33663.06 K</td>
    <td style="white-space: nowrap; text-align: right">0.0297 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;196.14%</td>
    <td style="white-space: nowrap; text-align: right">0.0410 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.0420 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">19685.23 K</td>
    <td style="white-space: nowrap; text-align: right">0.0508 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1305.04%</td>
    <td style="white-space: nowrap; text-align: right">0.0420 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.0840 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">3531.01 K</td>
    <td style="white-space: nowrap; text-align: right">0.28 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1812.51%</td>
    <td style="white-space: nowrap; text-align: right">0.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.50 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap; text-align: right">2731.28 K</td>
    <td style="white-space: nowrap; text-align: right">0.37 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;441.59%</td>
    <td style="white-space: nowrap; text-align: right">0.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.67 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap; text-align: right">2532.17 K</td>
    <td style="white-space: nowrap; text-align: right">0.39 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;240.85%</td>
    <td style="white-space: nowrap; text-align: right">0.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">0.88 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap; text-align: right">283.68 K</td>
    <td style="white-space: nowrap; text-align: right">3.53 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;204.28%</td>
    <td style="white-space: nowrap; text-align: right">3.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">6.67 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap; text-align: right">195.00 K</td>
    <td style="white-space: nowrap; text-align: right">5.13 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;347.22%</td>
    <td style="white-space: nowrap; text-align: right">4.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">9.50 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap; text-align: right">68.19 K</td>
    <td style="white-space: nowrap; text-align: right">14.66 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;113.53%</td>
    <td style="white-space: nowrap; text-align: right">12.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">79.17 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap; text-align: right">60.81 K</td>
    <td style="white-space: nowrap; text-align: right">16.45 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;113.19%</td>
    <td style="white-space: nowrap; text-align: right">13.83 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">57.54 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap; text-align: right">44.72 K</td>
    <td style="white-space: nowrap; text-align: right">22.36 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;69.83%</td>
    <td style="white-space: nowrap; text-align: right">19.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">87.39 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap; text-align: right">44.26 K</td>
    <td style="white-space: nowrap; text-align: right">22.59 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;71.10%</td>
    <td style="white-space: nowrap; text-align: right">19.13 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">88.61 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap; text-align: right">43.83 K</td>
    <td style="white-space: nowrap; text-align: right">22.81 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;82.93%</td>
    <td style="white-space: nowrap; text-align: right">19.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">88.62 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap; text-align: right">43.75 K</td>
    <td style="white-space: nowrap; text-align: right">22.86 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;81.56%</td>
    <td style="white-space: nowrap; text-align: right">19.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">88.19 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap; text-align: right">42.99 K</td>
    <td style="white-space: nowrap; text-align: right">23.26 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;70.00%</td>
    <td style="white-space: nowrap; text-align: right">19.96 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">122.66 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap; text-align: right">42.80 K</td>
    <td style="white-space: nowrap; text-align: right">23.36 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;70.06%</td>
    <td style="white-space: nowrap; text-align: right">19.63 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">95.92 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap; text-align: right">41.95 K</td>
    <td style="white-space: nowrap; text-align: right">23.84 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;79.85%</td>
    <td style="white-space: nowrap; text-align: right">19.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">150.43 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap; text-align: right">41.56 K</td>
    <td style="white-space: nowrap; text-align: right">24.06 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;92.20%</td>
    <td style="white-space: nowrap; text-align: right">19.88 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">84.22 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap; text-align: right">41.25 K</td>
    <td style="white-space: nowrap; text-align: right">24.24 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;72.73%</td>
    <td style="white-space: nowrap; text-align: right">20.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">147.58 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap; text-align: right">39.47 K</td>
    <td style="white-space: nowrap; text-align: right">25.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;120.01%</td>
    <td style="white-space: nowrap; text-align: right">20.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">98.88 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap;text-align: right">34348.48 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap; text-align: right">33663.06 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">19685.23 K</td>
    <td style="white-space: nowrap; text-align: right">1.74x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap; text-align: right">3531.01 K</td>
    <td style="white-space: nowrap; text-align: right">9.73x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap; text-align: right">2731.28 K</td>
    <td style="white-space: nowrap; text-align: right">12.58x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap; text-align: right">2532.17 K</td>
    <td style="white-space: nowrap; text-align: right">13.56x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap; text-align: right">283.68 K</td>
    <td style="white-space: nowrap; text-align: right">121.08x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap; text-align: right">195.00 K</td>
    <td style="white-space: nowrap; text-align: right">176.15x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap; text-align: right">68.19 K</td>
    <td style="white-space: nowrap; text-align: right">503.7x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap; text-align: right">60.81 K</td>
    <td style="white-space: nowrap; text-align: right">564.87x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap; text-align: right">44.72 K</td>
    <td style="white-space: nowrap; text-align: right">768.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap; text-align: right">44.26 K</td>
    <td style="white-space: nowrap; text-align: right">776.06x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap; text-align: right">43.83 K</td>
    <td style="white-space: nowrap; text-align: right">783.64x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap; text-align: right">43.75 K</td>
    <td style="white-space: nowrap; text-align: right">785.13x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap; text-align: right">42.99 K</td>
    <td style="white-space: nowrap; text-align: right">799.03x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap; text-align: right">42.80 K</td>
    <td style="white-space: nowrap; text-align: right">802.52x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap; text-align: right">41.95 K</td>
    <td style="white-space: nowrap; text-align: right">818.76x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap; text-align: right">41.56 K</td>
    <td style="white-space: nowrap; text-align: right">826.57x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap; text-align: right">41.25 K</td>
    <td style="white-space: nowrap; text-align: right">832.66x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap; text-align: right">39.47 K</td>
    <td style="white-space: nowrap; text-align: right">870.19x</td>
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
    <td style="white-space: nowrap">Dictionary.size()</td>
    <td style="white-space: nowrap">0 KB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.all()</td>
    <td style="white-space: nowrap">0 KB</td>
    <td>1.0x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.count_between(4, 8)</td>
    <td style="white-space: nowrap">0.0234 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Dictionary.random_word_between(4, 8)</td>
    <td style="white-space: nowrap">0.0719 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Token.get_number(4)</td>
    <td style="white-space: nowrap">0.59 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">Token.get_number(2)</td>
    <td style="white-space: nowrap">0.59 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:xkcd)</td>
    <td style="white-space: nowrap">1.72 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:security)</td>
    <td style="white-space: nowrap">3.42 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:web32)</td>
    <td style="white-space: nowrap">10.87 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate(:wifi)</td>
    <td style="white-space: nowrap">12.24 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :upper</td>
    <td style="white-space: nowrap">17.28 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :lower</td>
    <td style="white-space: nowrap">17.28 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :capitalize</td>
    <td style="white-space: nowrap">17.28 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :alternate</td>
    <td style="white-space: nowrap">17.28 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">transform :random</td>
    <td style="white-space: nowrap">17.39 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">generate() default</td>
    <td style="white-space: nowrap">17.35 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 3 words</td>
    <td style="white-space: nowrap">17.21 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 4 words</td>
    <td style="white-space: nowrap">17.36 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 6 words</td>
    <td style="white-space: nowrap">17.68 KB</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">create() 5 words</td>
    <td style="white-space: nowrap">17.43 KB</td>
    <td>&mdash;</td>
  </tr>
</table>