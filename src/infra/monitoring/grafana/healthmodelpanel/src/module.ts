import { PanelPlugin } from '@grafana/data';
import { HealthModelPanelOptions } from './types';
import { HealthModelPanel } from './HealthModelPanel';

export const plugin = new PanelPlugin<HealthModelPanelOptions>(HealthModelPanel).setPanelOptions((builder) => {
  return builder
    .addTextInput({
      path: 'yellowThreshold',
      name: 'Yellow Threshold Value',
      defaultValue: '0.75',
    })
    .addTextInput({
      path: 'redThreshold',
      name: 'Red Threshold Value',
      defaultValue: '0.5',
    });
});
