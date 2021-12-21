import React from 'react';
import { PanelProps, DataFrameView } from '@grafana/data';
import { HealthModelPanelOptions } from 'types';
import { stylesFactory, useTheme } from '@grafana/ui';
import { HealthModelGraphComponent } from './HealthModelGraphComponent';
import { css, cx } from '@emotion/css';

interface Props extends PanelProps<HealthModelPanelOptions> {}

export const HealthModelPanel: React.FC<Props> = ({ options, data, width, height }) => {
  const theme = useTheme();
  const styles = getStyles();
  const view = new DataFrameView(data.series[0]);

  return (
    <div
      className={cx(
        styles.wrapper,
        css`
          width: ${width}px;
          height: ${height}px;
        `
      )}
    >
      <HealthModelGraphComponent
        width={width}
        height={height}
        yellowThreshold={options.yellowThreshold}
        redThreshold={options.redThreshold}
        theme={theme}
        data={view}
      />
    </div>
  );
};

const getStyles = stylesFactory(() => {
  return {
    wrapper: css`
      position: relative;
    `,
    svg: css`
      position: absolute;
      top: 0;
      left: 0;
    `,
    textBox: css`
      position: absolute;
      bottom: 0;
      left: 0;
      padding: 10px;
    `,
  };
});
